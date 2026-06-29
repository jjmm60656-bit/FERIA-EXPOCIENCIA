# ============================================================
# server.R — Logica del servidor con SQLite
# SISTEMA DE ANALISIS DE CONFIABILIDAD TERMO-HIDRAULICA
# FICCT - UAGRM
# ============================================================
library(shiny); library(shinydashboard); library(DT)
library(ggplot2); library(plotly); library(openxlsx)
library(rmarkdown); library(dplyr); library(DBI); library(RSQLite)
library(fitdistrplus)
source("ui.R")
source("database.R")
source("global.R")

shinyServer(function(input, output, session) {

  # Operador de coalescencia nula (definido primero, usado en todo el server)
  `%||%` <- function(a, b) {
    if (is.null(a)) return(b)
    if (length(a) == 0) return(b)
    if (length(a) == 1 && (is.na(a) || nchar(as.character(a)) == 0)) return(b)
    a
  }

  # ── ESTADO DE SESION (login propio) ──────────────────────
  sesion <- reactiveValues(
    autenticado = FALSE,
    usuario     = NULL,
    nombre      = NULL,
    rol         = NULL,
    error_login = NULL
  )

  es_admin <- reactive({
    isTRUE(sesion$autenticado) && identical(sesion$rol, "Administrador")
  })

  # ── LOGIN ─────────────────────────────────────────────────
  observeEvent(input$btn_login, {
    u <- trimws(input$login_usuario %||% "")
    p <- input$login_clave %||% ""
    if (nchar(u) == 0 || nchar(p) == 0) {
      sesion$error_login <- "Debe ingresar usuario y contrasena."
      return(invisible())
    }
    fila <- db_validar_login(u, p)
    if (is.null(fila)) {
      sesion$error_login <- "Usuario o contrasena incorrectos."
    } else {
      sesion$autenticado <- TRUE
      sesion$usuario <- fila$usuario
      sesion$nombre  <- fila$nombre_completo
      sesion$rol     <- fila$rol
      sesion$error_login <- NULL
    }
  })

  observeEvent(input$btn_logout, {
    sesion$autenticado <- FALSE
    sesion$usuario <- NULL
    sesion$nombre  <- NULL
    sesion$rol     <- NULL
    sesion$error_login <- NULL
  })

  # ── RENDER PRINCIPAL: login o app ────────────────────────
  output$pagina_principal <- renderUI({
    if (isTRUE(sesion$autenticado)) {
      ui_app
    } else {
      ui_login(sesion$error_login)
    }
  })

  output$usuario_sidebar <- renderUI({
    if (!isTRUE(sesion$autenticado)) return(NULL)
    div(style = "padding:8px 16px;",
      div(style = "color:#5fd6b8;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;",
          icon("user-circle"), " ", sesion$rol),
      div(style = "color:#cbd5e1;font-size:13px;margin-top:2px;", sesion$nombre)
    )
  })

  # ── MENU DINAMICO SEGUN ROL ───────────────────────────────
  output$menu_dinamico <- renderMenu({
    if (es_admin()) {
      sidebarMenu(
        id = "menu",
        menuItem("Dashboard",          tabName = "dashboard",     icon = icon("gauge-high")),
        menuItem("Registro de Fallas", tabName = "fallas",        icon = icon("triangle-exclamation"),
          menuSubItem("Ver Historial TBF",   tabName = "ver_fallas", icon = icon("list")),
          menuSubItem("Registrar Falla",     tabName = "add_falla",  icon = icon("plus-circle"))
        ),
        menuItem("Subsistemas",        tabName = "subsistemas",   icon = icon("sliders")),
        menuItem("Ajuste de Distrib.", tabName = "ajuste_dist",   icon = icon("calculator")),
        menuItem("Simulacion",         tabName = "montecarlo",    icon = icon("dice")),
        menuItem("Mantenimiento Optimo", tabName = "mantenimiento", icon = icon("screwdriver-wrench")),
        menuItem("AMEF",               tabName = "amef",          icon = icon("clipboard-list")),
        menuItem("Reportes",           tabName = "reportes",      icon = icon("file-alt"),
          menuSubItem("Reporte PDF",       tabName = "rep_pdf",   icon = icon("file-pdf")),
          menuSubItem("Exportar Excel",    tabName = "rep_excel", icon = icon("file-excel"))
        ),
        menuItem("Usuarios",           tabName = "usuarios",      icon = icon("users")),
        menuItem("Configuracion",      tabName = "config",        icon = icon("cog"))
      )
    } else {
      sidebarMenu(
        id = "menu",
        menuItem("Dashboard",          tabName = "dashboard",     icon = icon("gauge-high")),
        menuItem("Registro de Fallas", tabName = "fallas",        icon = icon("triangle-exclamation"),
          menuSubItem("Ver Historial TBF", tabName = "ver_fallas", icon = icon("list")),
          menuSubItem("Registrar Falla",   tabName = "add_falla",  icon = icon("plus-circle"))
        ),
        menuItem("Ajuste de Distrib.", tabName = "ajuste_dist",   icon = icon("calculator")),
        menuItem("Simulacion",         tabName = "montecarlo",    icon = icon("dice")),
        menuItem("AMEF",               tabName = "amef",          icon = icon("clipboard-list"))
      )
    }
  })

  # ── SEGURIDAD: bloquear pestanas restringidas al Analista ──
  tabs_analista <- c("dashboard", "ver_fallas", "add_falla", "ajuste_dist", "montecarlo", "amef")
  observeEvent(input$menu, {
    if (!es_admin() && !is.null(input$menu) && !(input$menu %in% tabs_analista)) {
      showNotification("No tiene permiso para acceder a esa seccion.", type = "error", duration = 4)
      updateTabItems(session, "menu", "dashboard")
    }
  }, ignoreInit = TRUE)

  observeEvent(input$ir_nueva_falla, {
    updateTabItems(session, "menu", "add_falla")
  })

  # ── ESTADO REACTIVO GLOBAL ────────────────────────────────
  cfg_ini0 <- db_config_cargar()
  rv <- reactiveValues(
    cfg = list(
      proyecto    = coalesce_str(cfg_ini0[["proyecto"]],    "Analisis de Confiabilidad Termo-Hidraulica"),
      institucion = coalesce_str(cfg_ini0[["institucion"]], "FICCT - UAGRM"),
      categoria   = coalesce_str(cfg_ini0[["categoria"]],   "Nivel Avanzado"),
      tutor       = coalesce_str(cfg_ini0[["tutor"]],       "MSc. Ing. Diego Antequera Virhuez"),
      descripcion = coalesce_str(cfg_ini0[["descripcion"]], "")
    ),
    trigger_fallas    = 0,
    trigger_subsis    = 0,
    trigger_amef      = 0,
    trigger_sim       = 0,
    trigger_mtto      = 0,
    trigger_usuarios  = 0,
    ultimo_ajuste     = NULL,
    ultima_sim        = NULL,
    ultimo_mtto       = NULL
  )

  # ── Datos reactivos desde BD ──────────────────────────────
  fallas_db <- reactive({
    rv$trigger_fallas
    df <- db_fallas()
    if (is.null(df) || nrow(df) == 0) return(fallas_inicial)
    df
  })

  subsistemas_db <- reactive({
    rv$trigger_subsis
    df <- db_subsistemas()
    if (is.null(df) || nrow(df) == 0) return(subsistemas_inicial)
    df
  })

  amef_db <- reactive({
    rv$trigger_amef
    df <- db_amef()
    if (is.null(df) || nrow(df) == 0) return(data.frame())
    df
  })

  dash <- reactive({
    rv$trigger_fallas; rv$trigger_amef; rv$trigger_sim; rv$trigger_mtto
    db_dashboard()
  })

  # ── Actualizar selectores dependientes ───────────────────
  observe({
    nombres_ss <- subsistemas_db()$nombre
    updateSelectInput(session, "ss_nombre", choices = nombres_ss)
  })

  # ── KPIs sidebar ──────────────────────────────────────────
  output$kpi_mtbf <- renderUI({
    df <- fallas_db()
    div(class = "kv", if (nrow(df) > 0) hrs(mean(df$tbf)) else "0 h")
  })
  output$kpi_fallas <- renderUI({
    df <- fallas_db()
    div(class = "kv", paste0(nrow(df), " registros"))
  })

  # ── MENU ALERTAS (modos AMEF criticos) ───────────────────
  output$menu_alertas <- renderMenu({
    df <- amef_db()
    if (nrow(df) == 0) {
      return(dropdownMenu(type = "notifications", badgeStatus = "warning",
                           headerText = "0 alertas criticas", .list = list()))
    }
    criticos <- df[df$npr > 150, ]
    items <- lapply(seq_len(min(nrow(criticos), 5)), function(i) {
      notificationItem(
        text   = paste0(criticos$modo_falla[i], " — NPR: ", round(criticos$npr[i], 0)),
        icon   = icon("triangle-exclamation"),
        status = "warning"
      )
    })
    dropdownMenu(type = "notifications", badgeStatus = "warning",
                 headerText = paste0(nrow(criticos), " alertas criticas (NPR>150)"),
                 .list = items)
  })

  # ══════════ DASHBOARD ════════════════════════════════════
  output$vb_mtbf <- renderValueBox({
    df <- fallas_db()
    valueBox(if (nrow(df) > 0) hrs(mean(df$tbf)) else "0 h", "MTBF Empirico", color = "yellow",
             icon = icon("clock"))
  })
  output$vb_cv <- renderValueBox({
    df <- fallas_db()
    cv <- if (nrow(df) > 0 && mean(df$tbf) > 0) sd(df$tbf) / mean(df$tbf) * 100 else 0
    valueBox(pct(cv), "Coef. de Variacion", color = "blue", icon = icon("chart-simple"))
  })
  output$vb_amef_alto <- renderValueBox({
    df <- amef_db()
    n <- if (nrow(df) > 0) sum(df$npr > 150) else 0
    valueBox(n, "Modos Criticos (NPR>150)", color = "red", icon = icon("triangle-exclamation"))
  })
  output$vb_n_fallas <- renderValueBox({
    df <- fallas_db()
    valueBox(nrow(df), "Fallas Registradas", color = "orange", icon = icon("list-check"))
  })
  output$vb_mejor_dist <- renderValueBox({
    txt <- if (!is.null(rv$ultimo_ajuste)) rv$ultimo_ajuste$mejor_nombre else "Sin ajustar"
    valueBox(txt, "Mejor Distribucion (AIC)", color = "purple", icon = icon("square-root-variable"))
  })
  output$vb_t_optimo <- renderValueBox({
    txt <- if (!is.null(rv$ultimo_mtto)) hrs(rv$ultimo_mtto$t_optimo) else "Sin calcular"
    valueBox(txt, "Intervalo Optimo t*", color = "blue", icon = icon("screwdriver-wrench"))
  })
  output$vb_confiab_mtbf <- renderValueBox({
    valueBox(pct(36.8), "R(MTBF) teorica", color = "yellow", icon = icon("shield-halved"))
  })
  output$vb_n_sim <- renderValueBox({
    df <- dash()
    valueBox(df$n_simulaciones, "Simulaciones Ejecutadas", color = "green", icon = icon("dice"))
  })

  # Histograma de TBF
  output$graf_tbf_historial <- renderPlotly({
    df <- fallas_db()
    if (is.null(df) || nrow(df) == 0) {
      return(plot_ly() %>% layout(paper_bgcolor = "#ffffff",
        annotations = list(list(text = "Sin fallas registradas aun", x = 0.5, y = 0.5,
          xref = "paper", yref = "paper", showarrow = FALSE, font = list(size = 14, color = "#94a3b8")))))
    }
    plot_ly(df, x = ~tbf, type = "histogram", nbinsx = 8,
            marker = list(color = "#0e7c66", line = list(color = "#0b5f96", width = 0.6)),
            hovertemplate = "TBF: %{x} h<br>Frecuencia: %{y}<extra></extra>") %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter,Segoe UI,sans-serif", color = "#475569", size = 11),
             xaxis = list(title = "Tiempo entre fallas (horas)", gridcolor = "#f1f5f9"),
             yaxis = list(title = "Frecuencia", gridcolor = "#f1f5f9"),
             bargap = 0.08, margin = list(t = 10, b = 40, l = 50, r = 20))
  })

  # Pie por subsistema
  output$graf_subsistema_pie <- renderPlotly({
    df <- fallas_db()
    if (is.null(df) || nrow(df) == 0) {
      return(plot_ly() %>% layout(paper_bgcolor = "#ffffff",
        annotations = list(list(text = "Sin datos aun", x = 0.5, y = 0.5,
          xref = "paper", yref = "paper", showarrow = FALSE, font = list(size = 14, color = "#94a3b8")))))
    }
    agg <- df %>% group_by(subsistema) %>% summarise(n = n(), .groups = "drop") %>% arrange(desc(n))
    colores <- c("#0e7c66", "#0b5f96", "#d97706", "#8b5cf6", "#dc2626")
    plot_ly(agg, labels = ~subsistema, values = ~n, type = "pie", hole = 0.45,
            marker = list(colors = colores[seq_len(nrow(agg))], line = list(color = "#ffffff", width = 2)),
            textinfo = "label+percent", textfont = list(color = "#fff", size = 10)) %>%
      layout(paper_bgcolor = "#ffffff", font = list(family = "Inter", color = "#475569"),
             legend = list(orientation = "h", y = -0.2), margin = list(t = 10, b = 50, l = 10, r = 10),
             annotations = list(list(text = "Fallas", x = 0.5, y = 0.5,
               showarrow = FALSE, font = list(size = 12, color = "#1e293b"))))
  })

  # Alertas AMEF
  output$alertas_amef <- renderUI({
    df <- amef_db()
    if (nrow(df) == 0) return(p(style = "color:#94a3b8;font-size:12px;", "Sin modos de falla registrados."))
    criticos <- df[df$npr > 150, ]
    if (nrow(criticos) == 0) return(p(style = "color:#059669;font-size:12px;", icon("circle-check"), " Sin modos criticos actualmente."))
    tagList(lapply(seq_len(min(nrow(criticos), 6)), function(i) {
      div(class = "alerta-stock",
          div(class = "at", criticos$modo_falla[i]),
          div(class = "an", paste0("NPR: ", round(criticos$npr[i], 0), " | Subsistema: ", criticos$subsistema[i])))
    }))
  })

  # Top modos de falla
  output$graf_top_modos <- renderPlotly({
    df <- fallas_db()
    if (is.null(df) || nrow(df) == 0) {
      return(plot_ly() %>% layout(paper_bgcolor = "#ffffff"))
    }
    agg <- df %>% group_by(modo_falla) %>% summarise(n = n(), .groups = "drop") %>%
      arrange(desc(n)) %>% head(5)
    plot_ly(agg, x = ~n, y = ~reorder(modo_falla, n), type = "bar", orientation = "h",
            marker = list(color = "#0b5f96")) %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Frecuencia", gridcolor = "#f1f5f9"),
             yaxis = list(title = ""), margin = list(t = 10, b = 30, l = 130, r = 20))
  })

  # Tabla ultimas fallas
  output$tabla_ultimas <- renderDT({
    df <- dash()$ultimas
    if (is.null(df) || nrow(df) == 0) return(datatable(data.frame(Mensaje = "Sin registros")))
    datatable(df, rownames = FALSE, options = list(dom = "t", pageLength = 10, scrollY = "220px"),
              colnames = c("Fecha", "TBF (h)", "Subsistema", "Modo de Falla", "Severidad"))
  })

  # ══════════ REGISTRO DE FALLAS — VER ═════════════════════
  output$tabla_fallas <- renderDT({
    df <- fallas_db()
    if (!is.null(input$filtro_subsis) && input$filtro_subsis != "Todos") {
      df <- df[df$subsistema == input$filtro_subsis, ]
    }
    if (!is.null(input$filtro_severidad) && input$filtro_severidad != "Todas") {
      df <- df[df$severidad == input$filtro_severidad, ]
    }
    badge <- function(s) switch(s,
      "Baja" = sprintf('<span class="badge-ok">%s</span>', s),
      "Media" = sprintf('<span class="badge-bajo">%s</span>', s),
      "Alta" = sprintf('<span class="badge-alto">%s</span>', s),
      "Critica" = sprintf('<span class="badge-alto">%s</span>', s),
      s)
    if (nrow(df) > 0) df$severidad <- sapply(df$severidad, badge)
    cols <- c("id", "fecha", "tbf", "subsistema", "modo_falla", "severidad", "censurado", "observaciones")
    cols <- cols[cols %in% names(df)]
    datatable(df[, cols, drop = FALSE], rownames = FALSE, escape = FALSE,
              options = list(pageLength = 10, order = list(list(0, "desc"))),
              colnames = c("ID", "Fecha", "TBF (h)", "Subsistema", "Modo de Falla",
                           "Severidad", "Censurado", "Observaciones"))
  })

  observeEvent(input$btn_refresh_fallas, { rv$trigger_fallas <- rv$trigger_fallas + 1 })

  # ══════════ REGISTRAR NUEVA FALLA ════════════════════════
  output$info_add_falla <- renderUI({
    tagList(
      div(class = "kpi-card-info", icon("circle-info"),
          " El TBF (Time Between Failures) es el tiempo, en horas, transcurrido desde la ultima ",
          "intervencion hasta que ocurre esta nueva falla."),
      div(class = "kpi-card-warn", icon("triangle-exclamation"),
          " Marque 'censurado' si el componente fue retirado o el periodo de observacion termino ",
          "sin que la falla ocurriera realmente (dato censurado a la derecha).")
    )
  })

  observeEvent(input$btn_agregar_falla, {
    if (is.null(input$nf_tbf) || input$nf_tbf <= 0) {
      showNotification("El TBF debe ser un valor positivo.", type = "error"); return()
    }
    ok <- db_nueva_falla(
      fecha = input$nf_fecha, tbf = input$nf_tbf, subsistema = input$nf_subsis,
      modo_falla = input$nf_modo, severidad = input$nf_severidad,
      censurado = input$nf_censurado, observaciones = input$nf_obs %||% "",
      registrado_por = sesion$usuario %||% "sistema"
    )
    if (ok) {
      showNotification("Falla registrada correctamente.", type = "message")
      rv$trigger_fallas <- rv$trigger_fallas + 1
      updateNumericInput(session, "nf_tbf", value = 100)
      updateTextAreaInput(session, "nf_obs", value = "")
    } else {
      showNotification("No se pudo registrar la falla.", type = "error")
    }
  })

  # ══════════ SUBSISTEMAS ═══════════════════════════════════
  observeEvent(input$ss_nombre, {
    df <- subsistemas_db()
    fila <- df[df$nombre == input$ss_nombre, ]
    if (nrow(fila) == 1) {
      updateNumericInput(session, "ss_beta", value = fila$beta[1])
      updateNumericInput(session, "ss_eta",  value = fila$eta[1])
      updateTextAreaInput(session, "ss_desc", value = fila$descripcion[1])
    }
  }, ignoreInit = FALSE)

  observeEvent(input$btn_guardar_subsis, {
    df <- subsistemas_db()
    fila <- df[df$nombre == input$ss_nombre, ]
    if (nrow(fila) == 1 && "id" %in% names(fila)) {
      db_actualizar_subsistema(fila$id[1], input$ss_beta, input$ss_eta, input$ss_desc %||% "")
      showNotification("Subsistema actualizado.", type = "message")
      rv$trigger_subsis <- rv$trigger_subsis + 1
    } else {
      showNotification("No se encontro el subsistema a actualizar.", type = "error")
    }
  })

  output$tabla_subsistemas <- renderDT({
    df <- subsistemas_db()
    df$mtbf <- round(mapply(calcular_mtbf_weibull, df$beta, df$eta), 1)
    df$tipo <- ifelse(df$beta < 1, "Fallas tempranas",
                ifelse(df$beta == 1, "Fallas aleatorias", "Desgaste"))
    cols <- c("nombre", "descripcion", "beta", "eta", "mtbf", "tipo")
    cols <- cols[cols %in% names(df)]
    datatable(df[, cols, drop = FALSE], rownames = FALSE, options = list(pageLength = 10, dom = "tip"),
              colnames = c("Subsistema", "Descripcion", "Beta", "Eta (h)", "MTBF (h)", "Fase de la curva"))
  })

  output$graf_curva_banera <- renderPlotly({
    df <- subsistemas_db()
    t_seq <- seq(1, 1000, length.out = 300)
    plt <- plot_ly()
    colores <- c("#0e7c66", "#0b5f96", "#d97706", "#8b5cf6", "#dc2626")
    for (i in seq_len(nrow(df))) {
      h_t <- tasa_falla_weibull(t_seq, df$beta[i], df$eta[i])
      plt <- plt %>% add_trace(x = t_seq, y = h_t, type = "scatter", mode = "lines",
                                name = df$nombre[i],
                                line = list(color = colores[((i - 1) %% length(colores)) + 1], width = 2.4))
    }
    plt %>% layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Tiempo (horas)", gridcolor = "#f1f5f9"),
             yaxis = list(title = "Tasa de falla h(t)", gridcolor = "#f1f5f9"),
             legend = list(orientation = "h", y = -0.25),
             margin = list(t = 10, b = 70, l = 60, r = 20))
  })

  # ══════════ AJUSTE DE DISTRIBUCIONES (AIC/BIC) ════════════
  observeEvent(input$btn_ajustar_dist, {
    df <- fallas_db()
    if (nrow(df) < 5) {
      showNotification("Se necesitan al menos 5 registros de TBF para ajustar distribuciones.", type = "error")
      return()
    }
    fits <- tryCatch(ajustar_distribuciones(df$tbf), error = function(e) NULL)
    if (is.null(fits) || length(fits) == 0) {
      showNotification("No se pudo ajustar ninguna distribucion con los datos actuales.", type = "error")
      return()
    }
    mejor <- names(fits)[1]
    rv$ultimo_ajuste <- list(fits = fits, mejor = mejor, mejor_nombre = nombre_dist(mejor))
    showNotification(paste("Ajuste completado. Mejor modelo:", nombre_dist(mejor)), type = "message")
  })

  output$ajuste_mejor_modelo <- renderUI({
    if (is.null(rv$ultimo_ajuste)) {
      return(div(class = "kpi-card-info", icon("circle-info"),
                  " Ejecute el ajuste para ver el modelo recomendado."))
    }
    fits <- rv$ultimo_ajuste$fits
    mejor <- rv$ultimo_ajuste$mejor
    params <- fits[[mejor]]$parametros
    parr_txt <- paste(sprintf("%s = %.4f", names(params), as.numeric(params)), collapse = ", ")
    div(class = "kpi-card-info",
        tags$b(icon("trophy"), " Mejor modelo: ", nombre_dist(mejor)), tags$br(),
        "Parametros estimados: ", parr_txt, tags$br(),
        "AIC = ", round(fits[[mejor]]$aic, 2), " | BIC = ", round(fits[[mejor]]$bic, 2))
  })

  output$tabla_aic_bic <- renderDT({
    if (is.null(rv$ultimo_ajuste)) return(datatable(data.frame(Mensaje = "Ejecute el ajuste primero")))
    tabla <- tabla_aic_bic(rv$ultimo_ajuste$fits)
    tabla$Ranking <- seq_len(nrow(tabla))
    datatable(tabla, rownames = FALSE, options = list(dom = "t", pageLength = 10))
  })

  output$graf_aic_bic <- renderPlotly({
    if (is.null(rv$ultimo_ajuste)) return(plot_ly() %>% layout(paper_bgcolor = "#ffffff"))
    tabla <- tabla_aic_bic(rv$ultimo_ajuste$fits)
    plot_ly(tabla, x = ~Distribucion, y = ~AIC, type = "bar", name = "AIC",
            marker = list(color = "#0e7c66")) %>%
      add_trace(y = ~BIC, name = "BIC", marker = list(color = "#0b5f96")) %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc", barmode = "group",
             font = list(family = "Inter", color = "#475569", size = 10),
             yaxis = list(title = "Valor del criterio", gridcolor = "#f1f5f9"),
             xaxis = list(title = ""), legend = list(orientation = "h", y = -0.3),
             margin = list(t = 10, b = 60, l = 50, r = 20))
  })

  output$graf_rt_comparativo <- renderPlotly({
    df <- fallas_db()
    lambda_hat <- 1 / mean(df$tbf)
    if (!is.null(rv$ultimo_ajuste) && "weibull" %in% names(rv$ultimo_ajuste$fits)) {
      p <- rv$ultimo_ajuste$fits[["weibull"]]$parametros
      beta_hat <- as.numeric(p["shape"]); eta_hat <- as.numeric(p["scale"])
    } else {
      beta_hat <- 1.64; eta_hat <- mean(df$tbf) / gamma(1 + 1 / 1.64)
    }
    t_seq <- seq(0, max(df$tbf) * 1.5, length.out = 300)
    r_weib <- confiabilidad_weibull(t_seq, beta_hat, eta_hat)
    r_exp  <- exp(-lambda_hat * t_seq)
    plot_ly() %>%
      add_trace(x = t_seq, y = r_weib, type = "scatter", mode = "lines", name = "Weibull ajustada",
                line = list(color = "#0e7c66", width = 2.6)) %>%
      add_trace(x = t_seq, y = r_exp, type = "scatter", mode = "lines", name = "Exponencial",
                line = list(color = "#d97706", width = 2, dash = "dash")) %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Tiempo t (horas)", gridcolor = "#f1f5f9"),
             yaxis = list(title = "Confiabilidad R(t)", range = c(0, 1), gridcolor = "#f1f5f9"),
             legend = list(orientation = "h", y = -0.2),
             margin = list(t = 10, b = 60, l = 50, r = 20))
  })

  # ══════════ SIMULACION MONTE CARLO ════════════════════════
  observeEvent(input$btn_correr_mc, {
    df <- subsistemas_db()
    params <- setNames(
      lapply(seq_len(nrow(df)), function(i) list(beta = df$beta[i], eta = df$eta[i])),
      df$nombre
    )
    n_rep <- input$mc_n %||% 10000
    semilla <- input$mc_semilla %||% 2026
    sim <- simulacion_montecarlo(params, N = n_rep, semilla = semilla)
    rv$ultima_sim <- sim
    db_registrar_simulacion(
      n_rep = n_rep, mtbf_sim = sim$mtbf_simulado, sd_sim = sim$sd_simulado,
      p10 = sim$percentil_10, p50 = sim$percentil_50,
      r150 = sim$confiabilidad(150), r250 = sim$confiabilidad(250), r400 = sim$confiabilidad(400),
      semilla = semilla, usuario = sesion$usuario %||% "sistema"
    )
    rv$trigger_sim <- rv$trigger_sim + 1
    showNotification("Simulacion Monte Carlo ejecutada y guardada.", type = "message")
  })

  output$mc_resultados <- renderUI({
    if (is.null(rv$ultima_sim)) {
      return(div(class = "kpi-card-info", icon("circle-info"),
                  " Ejecute la simulacion para ver los resultados."))
    }
    sim <- rv$ultima_sim
    tagList(
      fluidRow(
        column(6, div(class = "kpi-card-info", tags$b("MTBF simulado: "), hrs(sim$mtbf_simulado))),
        column(6, div(class = "kpi-card-info", tags$b("Desv. estandar: "), hrs(sim$sd_simulado)))
      ),
      fluidRow(
        column(6, div(class = "kpi-card-warn", tags$b("B10 life (P10): "), hrs(sim$percentil_10))),
        column(6, div(class = "kpi-card-warn", tags$b("Vida mediana (P50): "), hrs(sim$percentil_50)))
      ),
      div(class = "kpi-card-info",
          tags$b("Confiabilidad simulada — "),
          "R(150h) = ", pct(sim$confiabilidad(150) * 100), " | ",
          "R(250h) = ", pct(sim$confiabilidad(250) * 100), " | ",
          "R(400h) = ", pct(sim$confiabilidad(400) * 100))
    )
  })

  output$mc_grafico <- renderPlotly({
    if (is.null(rv$ultima_sim)) return(plot_ly() %>% layout(paper_bgcolor = "#ffffff"))
    plot_ly(x = rv$ultima_sim$t_sistema, type = "histogram", nbinsx = 40,
            marker = list(color = "#0b5f96")) %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Tiempo de falla del sistema (horas)", gridcolor = "#f1f5f9"),
             yaxis = list(title = "Frecuencia", gridcolor = "#f1f5f9"),
             margin = list(t = 10, b = 40, l = 50, r = 20))
  })

  output$tabla_simulaciones <- renderDT({
    rv$trigger_sim
    df <- db_simulaciones()
    if (nrow(df) == 0) return(datatable(data.frame(Mensaje = "Sin simulaciones registradas")))
    df$mtbf_simulado <- round(df$mtbf_simulado, 1)
    df$sd_simulado   <- round(df$sd_simulado, 1)
    df$r150 <- pct(df$r150 * 100); df$r250 <- pct(df$r250 * 100); df$r400 <- pct(df$r400 * 100)
    cols <- c("fecha", "n_replicas", "mtbf_simulado", "sd_simulado", "p10", "p50", "r150", "r250", "r400")
    datatable(df[, cols, drop = FALSE], rownames = FALSE, options = list(pageLength = 8),
              colnames = c("Fecha", "N Replicas", "MTBF Sim. (h)", "SD Sim. (h)",
                           "P10 (h)", "P50 (h)", "R(150h)", "R(250h)", "R(400h)"))
  })

  # ══════════ MANTENIMIENTO OPTIMO ══════════════════════════
  observeEvent(input$btn_calc_mtto, {
    res <- intervalo_optimo_mantenimiento(input$mt_beta, input$mt_eta, input$mt_cp, input$mt_cf)
    rv$ultimo_mtto <- res
    db_registrar_mantenimiento(
      beta = input$mt_beta, eta = input$mt_eta, cp = input$mt_cp, cf = input$mt_cf,
      t_opt = res$t_optimo, costo_opt = res$costo_optimo, ahorro = res$ahorro_pct
    )
    rv$trigger_mtto <- rv$trigger_mtto + 1
    showNotification(paste0("Intervalo optimo calculado: ", round(res$t_optimo, 1), " h"), type = "message")
  })

  output$mtto_resultados <- renderUI({
    if (is.null(rv$ultimo_mtto)) {
      return(div(class = "kpi-card-info", icon("circle-info"),
                  " Ejecute el calculo para obtener el intervalo optimo de mantenimiento."))
    }
    res <- rv$ultimo_mtto
    tagList(
      fluidRow(
        column(6, div(class = "kpi-card-warn", tags$b("Intervalo Optimo t*: "), hrs(res$t_optimo))),
        column(6, div(class = "kpi-card-warn", tags$b("Costo Minimo Esperado: "),
                       paste0(usd(res$costo_optimo), " / h")))
      ),
      div(class = "kpi-card-info", icon("piggy-bank"),
          " Ahorro estimado respecto al mantenimiento puramente correctivo: ",
          tags$b(pct(res$ahorro_pct)))
    )
  })

  output$mtto_grafico <- renderPlotly({
    if (is.null(rv$ultimo_mtto)) return(plot_ly() %>% layout(paper_bgcolor = "#ffffff"))
    res <- rv$ultimo_mtto
    plot_ly(x = res$t_seq, y = res$costos, type = "scatter", mode = "lines",
            line = list(color = "#0b5f96", width = 2.4), name = "Costo esperado") %>%
      add_trace(x = c(res$t_optimo), y = c(res$costo_optimo), type = "scatter", mode = "markers",
                marker = list(color = "#dc2626", size = 11), name = "Optimo t*") %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Intervalo de mantenimiento (horas)", gridcolor = "#f1f5f9"),
             yaxis = list(title = "Costo esperado (USD/h)", gridcolor = "#f1f5f9"),
             legend = list(orientation = "h", y = -0.25),
             margin = list(t = 10, b = 60, l = 60, r = 20))
  })

  output$tabla_mantenimientos <- renderDT({
    rv$trigger_mtto
    df <- db_mantenimientos()
    if (nrow(df) == 0) return(datatable(data.frame(Mensaje = "Sin calculos registrados")))
    df$t_optimo <- round(df$t_optimo, 1); df$costo_optimo <- round(df$costo_optimo, 3)
    df$ahorro_pct <- pct(df$ahorro_pct)
    cols <- c("fecha", "beta", "eta", "costo_preventivo", "costo_correctivo", "t_optimo", "costo_optimo", "ahorro_pct")
    datatable(df[, cols, drop = FALSE], rownames = FALSE, options = list(pageLength = 8),
              colnames = c("Fecha", "Beta", "Eta (h)", "Cp (USD)", "Cf (USD)",
                           "t* Optimo (h)", "Costo Optimo (USD/h)", "Ahorro %"))
  })

  # ══════════ AMEF ═══════════════════════════════════════════
  output$amef_npr_preview <- renderUI({
    npr <- (input$amef_s %||% 5) * (input$amef_o %||% 5) * (input$amef_d %||% 5)
    nivel <- if (npr > 150) "badge-alto" else if (npr > 80) "badge-bajo" else "badge-ok"
    div(style = "margin:8px 0 14px;",
        tags$b("NPR calculado: "),
        tags$span(class = nivel, npr))
  })

  observeEvent(input$btn_agregar_amef, {
    if (nchar(trimws(input$amef_modo %||% "")) == 0) {
      showNotification("Debe indicar el modo de falla.", type = "error"); return()
    }
    ok <- db_nuevo_amef(input$amef_modo, input$amef_efecto %||% "", input$amef_subsis,
                        input$amef_s, input$amef_o, input$amef_d, input$amef_accion %||% "")
    if (ok) {
      showNotification("Modo de falla registrado en el AMEF.", type = "message")
      rv$trigger_amef <- rv$trigger_amef + 1
      updateTextInput(session, "amef_modo", value = "")
      updateTextInput(session, "amef_efecto", value = "")
      updateTextAreaInput(session, "amef_accion", value = "")
    } else {
      showNotification("No se pudo registrar el modo de falla.", type = "error")
    }
  })

  output$graf_npr <- renderPlotly({
    df <- amef_db()
    if (nrow(df) == 0) return(plot_ly() %>% layout(paper_bgcolor = "#ffffff"))
    df <- df %>% arrange(desc(npr))
    colores <- ifelse(df$npr > 150, "#dc2626", ifelse(df$npr > 80, "#d97706", "#0e7c66"))
    plot_ly(df, x = ~npr, y = ~reorder(modo_falla, npr), type = "bar", orientation = "h",
            marker = list(color = colores),
            hovertemplate = "%{y}<br>NPR: %{x}<extra></extra>") %>%
      layout(paper_bgcolor = "#ffffff", plot_bgcolor = "#f8fafc",
             font = list(family = "Inter", color = "#475569", size = 10),
             xaxis = list(title = "Numero de Prioridad de Riesgo (NPR)", gridcolor = "#f1f5f9"),
             yaxis = list(title = ""), shapes = list(
               list(type = "line", x0 = 150, x1 = 150, y0 = -0.5, y1 = nrow(df) - 0.5,
                    line = list(color = "#7f1d1d", dash = "dot", width = 1.4))
             ),
             margin = list(t = 10, b = 40, l = 160, r = 20))
  })

  output$tabla_amef <- renderDT({
    df <- amef_db()
    if (nrow(df) == 0) return(datatable(data.frame(Mensaje = "Sin registros AMEF")))
    badge <- function(n) {
      if (n > 150) sprintf('<span class="badge-alto">%s</span>', round(n, 0))
      else if (n > 80) sprintf('<span class="badge-bajo">%s</span>', round(n, 0))
      else sprintf('<span class="badge-ok">%s</span>', round(n, 0))
    }
    df$npr_fmt <- sapply(df$npr, badge)
    cols <- c("modo_falla", "efecto", "subsistema", "severidad", "ocurrencia", "deteccion", "npr_fmt", "accion_recomendada")
    datatable(df[, cols, drop = FALSE], rownames = FALSE, escape = FALSE,
              options = list(pageLength = 10),
              colnames = c("Modo de Falla", "Efecto", "Subsistema", "S", "O", "D", "NPR", "Accion Recomendada"))
  })

  # ══════════ REPORTE PDF ════════════════════════════════════
  output$preview_reporte <- renderUI({
    df <- fallas_db()
    mtbf <- if (nrow(df) > 0) mean(df$tbf) else 0
    cv <- if (mtbf > 0) sd(df$tbf) / mtbf * 100 else 0
    tagList(
      h4(style = "color:#0b2e3d;font-weight:700;", input$rep_proyecto),
      p(style = "color:#64748b;font-size:12px;", input$rep_institucion, " | ",
        mes_nombre(as.integer(input$rep_mes)), " ", input$rep_anio),
      tags$hr(),
      div(class = "kpi-card-info", tags$b("Fallas registradas: "), nrow(df)),
      div(class = "kpi-card-info", tags$b("MTBF empirico: "), hrs(mtbf)),
      div(class = "kpi-card-info", tags$b("Coeficiente de variacion: "), pct(cv)),
      div(class = "kpi-card-warn", tags$b("Modos AMEF criticos (NPR>150): "),
          { a <- amef_db(); if (nrow(a) > 0) sum(a$npr > 150) else 0 }),
      p(style = "color:#94a3b8;font-size:11px;margin-top:10px;",
        "El PDF incluira: estadistica descriptiva, ajuste de distribuciones, AMEF, ",
        "resultados de simulacion Monte Carlo y el intervalo optimo de mantenimiento.")
    )
  })

  output$btn_gen_pdf <- downloadHandler(
    filename = function() paste0("Reporte_Confiabilidad_", mes_nombre(as.integer(input$rep_mes)), "_", input$rep_anio, ".pdf"),
    content = function(file) {
      df <- fallas_db()
      amefdf <- amef_db()
      mtbf <- if (nrow(df) > 0) mean(df$tbf) else 0
      sdv  <- if (nrow(df) > 0) sd(df$tbf) else 0
      cv   <- if (mtbf > 0) sdv / mtbf * 100 else 0

      tmp_rmd <- file.path(tempdir(), "reporte_confiabilidad.Rmd")
      rmd_txt <- paste0(
        "---\n",
        "title: \"", gsub('"', "'", input$rep_proyecto), "\"\n",
        "subtitle: \"", gsub('"', "'", input$rep_institucion), " - ",
        mes_nombre(as.integer(input$rep_mes)), " ", input$rep_anio, "\"\n",
        "output: pdf_document\n",
        "---\n\n",
        "## Resumen Ejecutivo\n\n",
        "Numero de fallas registradas: **", nrow(df), "**\n\n",
        "MTBF empirico: **", round(mtbf, 2), " horas**\n\n",
        "Desviacion estandar: **", round(sdv, 2), " horas**\n\n",
        "Coeficiente de variacion: **", round(cv, 2), "%**\n\n",
        "## Tabla de Tiempos Entre Fallas (resumen)\n\n",
        "```{r echo=FALSE}\n",
        "knitr::kable(head(df[order(-df$id), c('fecha','tbf','subsistema','modo_falla','severidad')], 15))\n",
        "```\n\n",
        "## Analisis de Modos y Efectos de Falla (AMEF)\n\n",
        "```{r echo=FALSE}\n",
        "if (nrow(amefdf) > 0) knitr::kable(amefdf[order(-amefdf$npr), c('modo_falla','subsistema','severidad','ocurrencia','deteccion','npr')]) else cat('Sin registros AMEF.')\n",
        "```\n\n",
        "## Conclusiones\n\n",
        "El presente reporte fue generado automaticamente por el Sistema de Analisis de Confiabilidad ",
        "Termo-Hidraulica, FICCT - UAGRM. Tutor: ", gsub('"', "'", input$rep_tutor), "."
      )
      writeLines(rmd_txt, tmp_rmd)

      ok <- tryCatch({
        rmarkdown::render(tmp_rmd, output_file = file, output_format = "pdf_document",
                           envir = new.env(), quiet = TRUE)
        TRUE
      }, error = function(e) { cat("[PDF ERROR]", conditionMessage(e), "\n"); FALSE })

      if (!isTRUE(ok) || !file.exists(file)) {
        # Fallback: PDF simple via grDevices si no hay LaTeX disponible
        pdf(file, width = 8.27, height = 11.69)
        plot.new()
        text(0.5, 0.95, input$rep_proyecto, cex = 1.3, font = 2)
        text(0.5, 0.90, paste0(input$rep_institucion, " - ", mes_nombre(as.integer(input$rep_mes)), " ", input$rep_anio), cex = 0.9)
        text(0.1, 0.80, paste0("Fallas registradas: ", nrow(df)), adj = 0, cex = 0.9)
        text(0.1, 0.76, paste0("MTBF empirico: ", round(mtbf, 2), " horas"), adj = 0, cex = 0.9)
        text(0.1, 0.72, paste0("Desviacion estandar: ", round(sdv, 2), " horas"), adj = 0, cex = 0.9)
        text(0.1, 0.68, paste0("Coeficiente de variacion: ", round(cv, 2), "%"), adj = 0, cex = 0.9)
        text(0.1, 0.60, "Nota: instale una distribucion de LaTeX (ej. tinytex::install_tinytex())", adj = 0, cex = 0.75, col = "gray40")
        text(0.1, 0.57, "para generar el reporte PDF con formato completo.", adj = 0, cex = 0.75, col = "gray40")
        dev.off()
      }
    },
    contentType = "application/pdf"
  )

  # ══════════ EXPORTAR EXCEL ══════════════════════════════════
  output$preview_excel <- renderUI({
    df <- fallas_db()
    amefdf <- amef_db()
    tagList(
      div(class = "kpi-card-info", tags$b("Hoja 1 - Fallas: "), nrow(df), " registros"),
      div(class = "kpi-card-info", tags$b("Hoja 2 - AMEF: "), nrow(amefdf), " modos de falla"),
      div(class = "kpi-card-info", tags$b("Hoja 3 - Simulaciones: "), nrow(db_simulaciones()), " corridas Monte Carlo"),
      div(class = "kpi-card-info", tags$b("Hoja 4 - Mantenimiento: "), nrow(db_mantenimientos()), " calculos de t* optimo")
    )
  })

  output$btn_gen_excel <- downloadHandler(
    filename = function() paste0("Confiabilidad_TermoHidraulico_", Sys.Date(), ".xlsx"),
    content = function(file) {
      wb <- createWorkbook()
      estilo_header <- createStyle(fontColour = "#FFFFFF", fgFill = "#0b2e3d",
                                    halign = "center", textDecoration = "bold", border = "TopBottomLeftRight")

      addWorksheet(wb, "Fallas TBF")
      writeData(wb, "Fallas TBF", fallas_db(), headerStyle = estilo_header)
      setColWidths(wb, "Fallas TBF", cols = 1:8, widths = 16)

      addWorksheet(wb, "AMEF")
      writeData(wb, "AMEF", amef_db(), headerStyle = estilo_header)
      setColWidths(wb, "AMEF", cols = 1:9, widths = 18)

      addWorksheet(wb, "Simulaciones MC")
      writeData(wb, "Simulaciones MC", db_simulaciones(), headerStyle = estilo_header)
      setColWidths(wb, "Simulaciones MC", cols = 1:11, widths = 16)

      addWorksheet(wb, "Mantenimiento Optimo")
      writeData(wb, "Mantenimiento Optimo", db_mantenimientos(), headerStyle = estilo_header)
      setColWidths(wb, "Mantenimiento Optimo", cols = 1:9, widths = 16)

      addWorksheet(wb, "Resumen")
      df <- fallas_db()
      mtbf <- if (nrow(df) > 0) mean(df$tbf) else 0
      resumen <- data.frame(
        Indicador = c("Fallas registradas", "MTBF empirico (h)", "Desviacion estandar (h)",
                      "Coeficiente de variacion (%)", "Modos AMEF criticos (NPR>150)"),
        Valor = c(nrow(df), round(mtbf, 2), round(sd(df$tbf), 2),
                  round(sd(df$tbf) / mtbf * 100, 2),
                  { a <- amef_db(); if (nrow(a) > 0) sum(a$npr > 150) else 0 })
      )
      writeData(wb, "Resumen", resumen, headerStyle = estilo_header)
      setColWidths(wb, "Resumen", cols = 1:2, widths = 30)

      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )

  # ══════════ GESTION DE USUARIOS ═════════════════════════════
  observeEvent(input$btn_agregar_usuario, {
    if (nchar(trimws(input$us_usuario %||% "")) == 0 || nchar(input$us_clave %||% "") == 0) {
      showNotification("Usuario y contrasena son obligatorios.", type = "error"); return()
    }
    ok <- db_nuevo_usuario(input$us_usuario, input$us_clave, input$us_nombre %||% "", input$us_rol)
    if (ok) {
      showNotification("Usuario creado correctamente.", type = "message")
      rv$trigger_usuarios <- rv$trigger_usuarios + 1
      updateTextInput(session, "us_usuario", value = "")
      updateTextInput(session, "us_clave", value = "")
      updateTextInput(session, "us_nombre", value = "")
    } else {
      showNotification("No se pudo crear el usuario (puede que ya exista).", type = "error")
    }
  })

  output$tabla_usuarios <- renderDT({
    rv$trigger_usuarios
    df <- db_usuarios()
    if (nrow(df) == 0) return(datatable(data.frame(Mensaje = "Sin usuarios")))
    df$estado <- ifelse(df$activo == 1,
                         '<span class="badge-ok">Activo</span>',
                         '<span class="badge-alto">Inactivo</span>')
    df$accion <- sapply(df$id, function(id) {
      paste0(
        '<button class="btn btn-xs btn-warning" onclick="Shiny.setInputValue(\'us_toggle\', ', id, ', {priority:\'event\'})">Activar/Desactivar</button> ',
        '<button class="btn btn-xs btn-danger" onclick="Shiny.setInputValue(\'us_delete\', ', id, ', {priority:\'event\'})">Eliminar</button>'
      )
    })
    cols <- c("usuario", "nombre_completo", "rol", "estado", "creado", "accion")
    datatable(df[, cols, drop = FALSE], rownames = FALSE, escape = FALSE,
              options = list(pageLength = 10, dom = "tip"),
              colnames = c("Usuario", "Nombre Completo", "Rol", "Estado", "Creado", "Acciones"))
  })

  observeEvent(input$us_toggle, {
    df <- db_usuarios()
    fila <- df[df$id == input$us_toggle, ]
    if (nrow(fila) == 1) {
      if (identical(fila$usuario[1], "admin")) {
        showNotification("No se puede desactivar al administrador principal.", type = "error"); return()
      }
      db_cambiar_estado_usuario(fila$id[1], !as.logical(fila$activo[1]))
      rv$trigger_usuarios <- rv$trigger_usuarios + 1
    }
  })

  observeEvent(input$us_delete, {
    df <- db_usuarios()
    fila <- df[df$id == input$us_delete, ]
    if (nrow(fila) == 1) {
      if (identical(fila$usuario[1], "admin")) {
        showNotification("No se puede eliminar al administrador principal.", type = "error"); return()
      }
      db_eliminar_usuario(fila$id[1])
      rv$trigger_usuarios <- rv$trigger_usuarios + 1
      showNotification("Usuario eliminado.", type = "message")
    }
  })

  # ══════════ CONFIGURACION ════════════════════════════════════
  observeEvent(input$btn_guardar_cfg, {
    db_config_guardar("proyecto", input$cfg_proyecto)
    db_config_guardar("institucion", input$cfg_institucion)
    db_config_guardar("categoria", input$cfg_categoria)
    db_config_guardar("tutor", input$cfg_tutor)
    db_config_guardar("descripcion", input$cfg_descripcion)
    rv$cfg <- list(proyecto = input$cfg_proyecto, institucion = input$cfg_institucion,
                   categoria = input$cfg_categoria, tutor = input$cfg_tutor,
                   descripcion = input$cfg_descripcion)
    showNotification("Configuracion guardada correctamente.", type = "message")
  })

})
