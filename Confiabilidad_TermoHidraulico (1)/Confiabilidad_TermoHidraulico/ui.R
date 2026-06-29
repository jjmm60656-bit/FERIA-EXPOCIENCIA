# ============================================================
# ui.R — Interfaz de Usuario
# SISTEMA DE ANALISIS DE CONFIABILIDAD TERMO-HIDRAULICA
# FICCT - UAGRM | Feria Facultativa 1/2026
# ============================================================

css <- "
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
* { box-sizing: border-box; }
body, .content-wrapper { background: #f1f5f9 !important; font-family: 'Inter','Segoe UI',sans-serif !important; }

/* ===== LOGIN ===== */
.login-page-wrap { min-height: 100vh; display:flex; align-items:center; justify-content:center;
  background: linear-gradient(135deg,#0b2e3d,#114b63 55%,#0e7c66); padding: 24px; }
.login-card { background:#ffffff; border-radius:16px; width:100%; max-width:420px;
  box-shadow:0 20px 50px rgba(0,0,0,0.35); padding:36px 34px 28px; }
.login-card .lg-icon { text-align:center; margin-bottom:6px; }
.login-card .lg-icon .fa { font-size:44px; color:#0e7c66; }
.login-card h2 { text-align:center; color:#0b2e3d; font-weight:700; font-size:19px; margin:6px 0 2px; }
.login-card .lg-sub { text-align:center; color:#64748b; font-size:12px; margin-bottom:22px; }
.login-card .form-control { height:42px; border-radius:8px; border:1.5px solid #e2e8f0; font-size:13.5px; }
.login-card .form-control:focus { border-color:#0e7c66; box-shadow:0 0 0 3px rgba(14,124,102,0.15); }
.login-card label { color:#374151; font-weight:600; font-size:12px; text-transform:uppercase; letter-spacing:.4px; }
.btn-login { width:100%; background:linear-gradient(135deg,#0e7c66,#114b63) !important; color:#fff !important;
  border:none !important; border-radius:9px !important; font-weight:700 !important; height:44px; font-size:14px;
  margin-top:6px; box-shadow:0 6px 16px rgba(14,124,102,0.35); }
.btn-login:hover { transform:translateY(-1px); box-shadow:0 8px 22px rgba(14,124,102,0.45); }
.login-error { background:#fef2f2; border:1.5px solid #fca5a5; color:#7f1d1d; border-radius:8px;
  padding:9px 12px; font-size:12.5px; margin-bottom:14px; text-align:center; }
.login-demo { margin-top:18px; background:#f0fdf9; border:1px dashed #99d8c9; border-radius:8px;
  padding:10px 12px; font-size:11.5px; color:#0b2e3d; text-align:center; line-height:1.6; }

/* Header */
.main-header .logo { background: #0b2e3d !important; color: #5fd6b8 !important; font-weight: 700 !important; font-size: 12.5px !important; letter-spacing: 0.3px !important; border-bottom: none !important; }
.main-header .navbar { background: #0b2e3d !important; border-bottom: 2px solid #0e7c66 !important; }
.main-header .navbar .nav > li > a { color: #94a3b8 !important; }
.main-header .sidebar-toggle { color: #5fd6b8 !important; font-size: 18px !important; }
.main-header .sidebar-toggle:hover { color: #ffffff !important; background: rgba(14,124,102,0.25) !important; }
.main-header .navbar .sidebar-toggle:before { color: #5fd6b8 !important; }

/* Sidebar */
.main-sidebar { background: #0a2233 !important; }
.sidebar-menu > li { margin: 2px 8px; }
.sidebar-menu > li > a { color: #8fb0c2 !important; font-size: 13px !important; font-weight: 500 !important; padding: 10px 14px !important; border-radius: 8px !important; border-left: none !important; transition: all 0.2s !important; }
.sidebar-menu > li.active > a { color: #fff !important; background: linear-gradient(90deg,#0e7c66,#0b5f96) !important; font-weight: 600 !important; }
.sidebar-menu > li > a:hover { color: #e2e8f0 !important; background: rgba(14,124,102,0.2) !important; }
.sidebar-menu > li > a > .fa { width: 18px !important; margin-right: 8px !important; }
.sidebar-menu .treeview-menu > li > a { color: #7aa0b8 !important; font-size: 12px !important; padding: 7px 14px 7px 32px !important; }
.sidebar-menu .treeview-menu > li.active > a { color: #5fd6b8 !important; }

/* Inputs sidebar */
.main-sidebar .form-group label { color: #7aa0b8 !important; font-size: 10px !important; font-weight: 600 !important; text-transform: uppercase !important; letter-spacing: 0.6px !important; }
.main-sidebar .form-control { background: rgba(255,255,255,0.07) !important; border: 1px solid rgba(255,255,255,0.15) !important; border-radius: 6px !important; color: #e2e8f0 !important; font-size: 13px !important; height: 34px !important; padding: 4px 10px !important; }
.main-sidebar .selectize-control .selectize-input { background: rgba(255,255,255,0.07) !important; border: 1px solid rgba(255,255,255,0.15) !important; color: #e2e8f0 !important; border-radius: 6px !important; }
.main-sidebar .selectize-dropdown { background: #0a2233 !important; border: 1px solid rgba(14,124,102,0.4) !important; color: #e2e8f0 !important; }

/* Inputs body */
.content-wrapper .form-group label { color: #374151 !important; font-size: 12px !important; font-weight: 600 !important; text-transform: uppercase !important; letter-spacing: 0.4px !important; }
.content-wrapper .form-control { background: #fff !important; border: 1.5px solid #e2e8f0 !important; border-radius: 7px !important; color: #1e293b !important; font-size: 13px !important; height: 38px !important; padding: 6px 12px !important; }
.content-wrapper .form-control:focus { border-color: #0e7c66 !important; box-shadow: 0 0 0 3px rgba(14,124,102,0.15) !important; outline: none !important; }
.content-wrapper textarea.form-control { height: auto !important; }
.content-wrapper .selectize-control .selectize-input { background: #fff !important; border: 1.5px solid #e2e8f0 !important; border-radius: 7px !important; color: #1e293b !important; font-size: 13px !important; }
.content-wrapper .selectize-dropdown { background: #fff !important; border: 1px solid #e2e8f0 !important; color: #1e293b !important; border-radius: 7px !important; box-shadow: 0 4px 16px rgba(0,0,0,0.1) !important; }
.content-wrapper .selectize-dropdown .option:hover { background: #f0fdf9 !important; }

/* Value Boxes */
.small-box { border-radius: 12px !important; border: none !important; box-shadow: 0 2px 12px rgba(0,0,0,0.1) !important; transition: all 0.2s !important; overflow: hidden !important; position: relative !important; }
.small-box:hover { transform: translateY(-2px) !important; box-shadow: 0 6px 20px rgba(0,0,0,0.18) !important; }
.small-box.bg-yellow { background: linear-gradient(135deg,#92400e,#d97706) !important; }
.small-box.bg-blue   { background: linear-gradient(135deg,#0b3a5c,#0b5f96) !important; }
.small-box.bg-green  { background: linear-gradient(135deg,#065f46,#0e7c66) !important; }
.small-box.bg-red    { background: linear-gradient(135deg,#991b1b,#ef4444) !important; }
.small-box.bg-purple { background: linear-gradient(135deg,#4c1d95,#8b5cf6) !important; }
.small-box.bg-orange { background: linear-gradient(135deg,#78350f,#d97706) !important; }
.small-box .inner h3 { font-size: 22px !important; font-weight: 700 !important; }
.small-box .inner p  { font-size: 11px !important; text-transform: uppercase !important; letter-spacing: 0.5px !important; }
.small-box .icon { display: none !important; }
.small-box > .inner { padding: 14px 18px !important; z-index: 2 !important; position: relative !important; width: 100% !important; }
.small-box h3 { font-size: 22px !important; font-weight: 700 !important; margin: 0 0 4px 0 !important; }
.small-box p { font-size: 11px !important; text-transform: uppercase !important; letter-spacing: 0.5px !important; margin: 0 !important; }

/* Cards */
.box { background: #fff !important; border: none !important; border-radius: 12px !important; box-shadow: 0 1px 6px rgba(0,0,0,0.07) !important; margin-bottom: 16px !important; }
.box-header { border-bottom: 1px solid #f1f5f9 !important; padding: 12px 16px !important; border-radius: 12px 12px 0 0 !important; }
.box-title { font-size: 12px !important; font-weight: 700 !important; text-transform: uppercase !important; letter-spacing: 0.5px !important; }
.box-body { padding: 14px 16px !important; }
.box.box-solid > .box-header { border-radius: 12px 12px 0 0 !important; }
.box.box-solid.box-primary > .box-header { background: linear-gradient(90deg,#0b3a5c,#0b5f96) !important; }
.box.box-solid.box-primary > .box-header .box-title { color: #fff !important; }
.box.box-solid.box-success  > .box-header { background: linear-gradient(90deg,#064e3b,#0e7c66) !important; }
.box.box-solid.box-success  > .box-header .box-title { color: #fff !important; }
.box.box-solid.box-warning  > .box-header { background: linear-gradient(90deg,#78350f,#d97706) !important; }
.box.box-solid.box-warning  > .box-header .box-title { color: #fff !important; }
.box.box-solid.box-danger   > .box-header { background: linear-gradient(90deg,#7f1d1d,#dc2626) !important; }
.box.box-solid.box-danger   > .box-header .box-title { color: #fff !important; }
.box.box-solid.box-info     > .box-header { background: linear-gradient(90deg,#0c4a6e,#0284c7) !important; }
.box.box-solid.box-info     > .box-header .box-title { color: #fff !important; }

/* Tablas */
table.dataTable { border-collapse: collapse !important; }
table.dataTable thead th { background: #f8fafc !important; color: #475569 !important; border-bottom: 2px solid #e2e8f0 !important; font-size: 11px !important; font-weight: 700 !important; text-transform: uppercase !important; letter-spacing: 0.4px !important; padding: 10px 12px !important; }
table.dataTable tbody td { border-top: 1px solid #f8fafc !important; color: #1e293b !important; font-size: 12.5px !important; padding: 9px 12px !important; }
table.dataTable tbody tr:nth-child(even) td { background: #fafbfd !important; }
table.dataTable tbody tr:hover td { background: #f0fdf9 !important; }
.dataTables_wrapper { color: #64748b !important; font-size: 12px !important; }
.dataTables_filter input { border: 1.5px solid #e2e8f0 !important; border-radius: 6px !important; padding: 4px 10px !important; background: #fff !important; color: #1e293b !important; }

/* Botones */
.btn-primary { background: linear-gradient(135deg,#0b5f96,#0284c7) !important; border: none !important; border-radius: 7px !important; font-weight: 600 !important; }
.btn-success { background: linear-gradient(135deg,#065f46,#0e7c66) !important; border: none !important; border-radius: 7px !important; font-weight: 600 !important; }
.btn-warning { background: linear-gradient(135deg,#92400e,#d97706) !important; border: none !important; border-radius: 7px !important; font-weight: 600 !important; color: #fff !important; }
.btn-danger  { background: linear-gradient(135deg,#7f1d1d,#dc2626) !important; border: none !important; border-radius: 7px !important; font-weight: 600 !important; }
.btn-info    { background: linear-gradient(135deg,#0c4a6e,#0284c7) !important; border: none !important; border-radius: 7px !important; font-weight: 600 !important; }

/* Botones de descarga grandes */
.dl-btn { width:100% !important; padding:12px 16px !important; font-size:14px !important; font-weight:600 !important; color:#fff !important; border-radius:8px !important; text-align:center !important; box-shadow:0 2px 8px rgba(0,0,0,0.15) !important; transition:all 0.2s !important; margin-top:4px !important; }
.dl-btn:hover { transform:translateY(-1px) !important; box-shadow:0 4px 14px rgba(0,0,0,0.25) !important; color:#fff !important; opacity:0.95 !important; }
.dl-btn .fa { margin-right:6px !important; }
#btn_gen_pdf.dl-btn  { background:linear-gradient(135deg,#7f1d1d,#dc2626) !important; }
#btn_gen_excel.dl-btn{ background:linear-gradient(135deg,#065f46,#0e7c66) !important; }

/* Badges de severidad / riesgo */
.badge-ok    { background:#d1fae5; color:#065f46; padding:3px 8px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-bajo  { background:#fef3c7; color:#92400e; padding:3px 8px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-alto  { background:#fee2e2; color:#7f1d1d; padding:3px 8px; border-radius:20px; font-size:11px; font-weight:600; }

/* KPI sidebar */
.kpi-s { margin: 4px 12px; background: rgba(14,124,102,0.12); border: 1px solid rgba(14,124,102,0.3); border-radius: 8px; padding: 10px 12px; }
.kpi-s .kl { color: #7aa0b8; font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.6px; }
.kpi-s .kv { color: #fff; font-size: 18px; font-weight: 700; margin-top: 2px; }
.kpi-s.gold .kv { color: #5fd6b8; }
.slbl { color: #5a7a9a; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; padding: 10px 16px 4px; display: block; }
.sdiv { border-color: rgba(14,124,102,0.25) !important; margin: 6px 12px !important; }

/* Alertas */
.alerta-stock { background: #fef2f2; border: 1.5px solid #fca5a5; border-radius: 8px; padding: 10px 14px; margin-bottom: 8px; }
.alerta-stock .at { color: #7f1d1d; font-size: 12px; font-weight: 600; }
.alerta-stock .an { color: #374151; font-size: 11px; margin-top: 2px; }

::-webkit-scrollbar { width: 5px; } ::-webkit-scrollbar-track { background: #f1f5f9; } ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
.content { padding: 14px !important; }

/* Boton principal del dashboard */
.btn-accion-principal { background: linear-gradient(135deg,#0e7c66,#0b5f96) !important; color:#fff !important; border:none !important; border-radius:10px !important; padding:12px 26px !important; font-size:14px !important; font-weight:700 !important; letter-spacing:0.3px !important; box-shadow:0 4px 14px rgba(14,124,102,0.35) !important; transition:all 0.2s !important; }
.btn-accion-principal:hover { transform:translateY(-2px) !important; box-shadow:0 6px 20px rgba(14,124,102,0.45) !important; color:#fff !important; }
.btn-accion-principal .fa { margin-right:4px !important; }

.kpi-card-info { background:#eff6ff; border-left:4px solid #0b5f96; border-radius:8px; padding:10px 14px; font-size:12px; color:#1e3a5c; margin-bottom:10px; }
.kpi-card-warn { background:#fffbeb; border-left:4px solid #d97706; border-radius:8px; padding:10px 14px; font-size:12px; color:#78350f; margin-bottom:10px; }
"

# ------------------------------------------------------------
# PANTALLA DE LOGIN (autenticacion propia, sin dependencias
# de archivos externos pre-generados)
# ------------------------------------------------------------
ui_login <- function(error_msg = NULL) {
  fluidPage(
    tags$head(tags$style(HTML(css)), tags$title("Acceso — Confiabilidad Termo-Hidraulica")),
    div(class = "login-page-wrap",
      div(class = "login-card",
        div(class = "lg-icon", icon("temperature-high")),
        h2("ANALISIS DE CONFIABILIDAD"),
        div(class = "lg-sub", "Sistema Termo-Hidraulico de Amortiguacion — FICCT/UAGRM"),
        if (!is.null(error_msg)) div(class = "login-error", icon("triangle-exclamation"), " ", error_msg),
        textInput("login_usuario", "Usuario:", placeholder = "Ingrese su usuario"),
        passwordInput("login_clave", "Contrasena:", placeholder = "Ingrese su contrasena"),
        actionButton("btn_login", tagList(icon("right-to-bracket"), " Ingresar al Sistema"),
                     class = "btn-login"),
        div(class = "login-demo",
            tags$b("Credenciales de demostracion:"), tags$br(),
            "Administrador → usuario: ", tags$b("admin"), " / clave: ", tags$b("Admin2026@"), tags$br(),
            "Analista → usuario: ", tags$b("analista"), " / clave: ", tags$b("Analista2026@"))
      )
    )
  )
}

# ------------------------------------------------------------
# APLICACION PRINCIPAL (dashboard tras autenticacion)
# ------------------------------------------------------------
ui_app <- dashboardPage(
  skin = "black",

  dashboardHeader(
    title = tags$span(
      style = "font-family:'Inter',sans-serif;font-weight:700;font-size:12.5px;",
      tags$i(class = "fa fa-temperature-high", style = "color:#5fd6b8;margin-right:6px;"),
      "CONFIABILIDAD TERMO-HIDRAULICA"
    ),
    titleWidth = 280,
    dropdownMenuOutput("menu_alertas"),
    tags$li(class = "dropdown",
      tags$a(href = "#", id = "btn_logout_link", onclick = "Shiny.setInputValue('btn_logout', Math.random());",
             style = "padding-top:18px;color:#5fd6b8;font-size:13px;",
             icon("right-from-bracket"), " Cerrar sesion")
    )
  ),

  dashboardSidebar(
    width = 280,
    tags$head(tags$style(HTML(css))),

    div(style = "padding:12px 0 6px;",
      tags$span(class = "slbl", "Resumen General"),
      div(class = "kpi-s gold",
          div(class = "kl", "MTBF Empirico"),
          uiOutput("kpi_mtbf")),
      div(class = "kpi-s", style = "margin-top:6px;",
          div(class = "kl", "Fallas Registradas"),
          uiOutput("kpi_fallas"))
    ),

    tags$hr(class = "sdiv"),
    uiOutput("usuario_sidebar"),
    tags$hr(class = "sdiv"),

    sidebarMenuOutput("menu_dinamico")
  ),

  dashboardBody(
    tabItems(

      # ════════ DASHBOARD ══════════════════════════════
      tabItem(tabName = "dashboard",
        fluidRow(
          column(width = 12,
            div(style = "margin-bottom:14px;display:flex;justify-content:flex-end;",
              actionButton("ir_nueva_falla",
                tagList(icon("plus"), "  Registrar Nueva Falla"),
                class = "btn-accion-principal")
            )
          )
        ),
        fluidRow(
          valueBoxOutput("vb_mtbf",        width = 3),
          valueBoxOutput("vb_cv",          width = 3),
          valueBoxOutput("vb_amef_alto",   width = 3),
          valueBoxOutput("vb_n_fallas",    width = 3)
        ),
        fluidRow(
          valueBoxOutput("vb_mejor_dist",  width = 3),
          valueBoxOutput("vb_t_optimo",    width = 3),
          valueBoxOutput("vb_confiab_mtbf",width = 3),
          valueBoxOutput("vb_n_sim",       width = 3)
        ),
        fluidRow(
          box(title = tagList(icon("chart-bar"), " Tiempos Entre Fallas (TBF) Registrados"),
              status = "warning", solidHeader = TRUE, width = 8,
              plotlyOutput("graf_tbf_historial", height = "280px")),
          box(title = tagList(icon("chart-pie"), " Fallas por Subsistema"),
              status = "info", solidHeader = TRUE, width = 4,
              plotlyOutput("graf_subsistema_pie", height = "280px"))
        ),
        fluidRow(
          box(title = tagList(icon("triangle-exclamation"), " Modos de Falla Criticos (NPR > 150)"),
              status = "danger", solidHeader = TRUE, width = 4,
              uiOutput("alertas_amef")),
          box(title = tagList(icon("ranking-star"), " Top Modos de Falla Frecuentes"),
              status = "success", solidHeader = TRUE, width = 4,
              plotlyOutput("graf_top_modos", height = "240px")),
          box(title = tagList(icon("table"), " Ultimas Fallas Registradas"),
              status = "primary", solidHeader = TRUE, width = 4,
              DTOutput("tabla_ultimas"))
        )
      ),

      # ════════ REGISTRO DE FALLAS — VER ════════════════
      tabItem(tabName = "ver_fallas",
        fluidRow(
          box(title = tagList(icon("list"), " Historial de Tiempos Entre Fallas (TBF)"),
              status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(3, selectInput("filtro_subsis", "Filtrar por Subsistema:",
                  choices = c("Todos", SUBSISTEMAS_NOMBRES))),
                column(3, selectInput("filtro_severidad", "Severidad:",
                  choices = c("Todas", SEVERIDADES))),
                column(3, br(), actionButton("btn_refresh_fallas", "Actualizar",
                  class = "btn btn-info", icon = icon("sync")))
              ),
              br(),
              DTOutput("tabla_fallas"))
        )
      ),

      # ════════ REGISTRAR NUEVA FALLA ═══════════════════
      tabItem(tabName = "add_falla",
        fluidRow(
          box(title = tagList(icon("plus-circle"), " Registrar Nueva Falla"),
              status = "success", solidHeader = TRUE, width = 6,
              dateInput("nf_fecha", "Fecha de la Falla:", value = Sys.Date()),
              numericInput("nf_tbf", "Tiempo Entre Fallas — TBF (horas):", value = 100, min = 0.1),
              selectInput("nf_subsis", "Subsistema Afectado:", choices = SUBSISTEMAS_NOMBRES),
              selectInput("nf_modo", "Modo de Falla:", choices = MODOS_FALLA),
              selectInput("nf_severidad", "Severidad:", choices = SEVERIDADES, selected = "Media"),
              checkboxInput("nf_censurado", "Observacion censurada (no se observo la falla, solo se sabe T > TBF)", value = FALSE),
              textAreaInput("nf_obs", "Observaciones:", rows = 2,
                            placeholder = "Detalle de la intervencion realizada..."),
              br(),
              actionButton("btn_agregar_falla", "Guardar Registro de Falla",
                           class = "btn btn-success btn-lg", icon = icon("save"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("info-circle"), " Informacion del Registro"),
              status = "info", solidHeader = TRUE, width = 6,
              uiOutput("info_add_falla"))
        )
      ),

      # ════════ GESTION DE SUBSISTEMAS ═══════════════════
      tabItem(tabName = "subsistemas",
        fluidRow(
          box(title = tagList(icon("sliders"), " Parametros Weibull por Subsistema"),
              status = "warning", solidHeader = TRUE, width = 6,
              selectInput("ss_nombre", "Subsistema:", choices = NULL),
              numericInput("ss_beta", "Parametro de Forma (beta):", value = 1.5, min = 0.1, step = 0.1),
              numericInput("ss_eta",  "Parametro de Escala — Vida Caracteristica (eta, horas):", value = 300, min = 1),
              textAreaInput("ss_desc", "Descripcion:", rows = 2),
              br(),
              actionButton("btn_guardar_subsis", "Actualizar Subsistema",
                           class = "btn btn-warning btn-lg", icon = icon("check"),
                           style = "width:100%;"),
              tags$hr(),
              h5(tagList(icon("circle-info"), " Interpretacion del parametro beta"), style="color:#374151;"),
              tags$ul(style = "color:#64748b;font-size:12px;padding-left:18px;",
                tags$li("beta < 1: fallas tempranas (mortalidad infantil)"),
                tags$li("beta = 1: fallas aleatorias (tasa constante, Exponencial)"),
                tags$li("beta > 1: fallas por desgaste (vejez del componente)")
              )
          ),
          box(title = tagList(icon("water"), " Curva de la Bañera del Sistema"),
              status = "info", solidHeader = TRUE, width = 6,
              plotlyOutput("graf_curva_banera", height = "320px"))
        ),
        fluidRow(
          box(title = tagList(icon("table-list"), " Subsistemas Configurados"),
              status = "primary", solidHeader = TRUE, width = 12,
              DTOutput("tabla_subsistemas"))
        )
      ),

      # ════════ SIMULACION MONTE CARLO ════════════════════
      tabItem(tabName = "montecarlo",
        fluidRow(
          box(title = tagList(icon("dice"), " Configurar Simulacion Monte Carlo"),
              status = "primary", solidHeader = TRUE, width = 5,
              p(style = "color:#374151;font-size:12.5px;line-height:1.6;",
                "El sistema se modela como tres subsistemas en serie (Sellos, Fluido Hidraulico, Mecanico). ",
                "La falla del sistema ocurre cuando el primero de ellos falla: ",
                tags$i("t_falla = min(T_sellos, T_fluido, T_mecanico).")),
              numericInput("mc_n", "Numero de Replicas (N):", value = 10000, min = 100, max = 100000, step = 1000),
              numericInput("mc_semilla", "Semilla aleatoria:", value = 2026, min = 1),
              br(),
              actionButton("btn_correr_mc", "Ejecutar Simulacion Monte Carlo",
                           class = "btn btn-primary btn-lg", icon = icon("play"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("chart-line"), " Resultados de la Simulacion"),
              status = "success", solidHeader = TRUE, width = 7,
              uiOutput("mc_resultados"),
              br(),
              plotlyOutput("mc_grafico", height = "260px"))
        ),
        fluidRow(
          box(title = tagList(icon("clock-rotate-left"), " Historial de Simulaciones Ejecutadas"),
              status = "info", solidHeader = TRUE, width = 12,
              DTOutput("tabla_simulaciones"))
        )
      ),

      # ════════ AJUSTE DE DISTRIBUCIONES (AIC/BIC) ════════
      tabItem(tabName = "ajuste_dist",
        fluidRow(
          box(title = tagList(icon("calculator"), " Ajuste de Distribuciones por Maxima Verosimilitud"),
              status = "warning", solidHeader = TRUE, width = 5,
              p(style = "color:#374151;font-size:12.5px;line-height:1.6;",
                "Se ajustan 4 distribuciones de vida (Exponencial, Weibull, Normal, Gamma) a los datos ",
                "historicos de TBF registrados y se comparan mediante los criterios AIC y BIC ",
                "(menor valor indica mejor ajuste)."),
              br(),
              actionButton("btn_ajustar_dist", "Ejecutar Ajuste de Distribuciones",
                           class = "btn btn-warning btn-lg", icon = icon("calculator"),
                           style = "width:100%;"),
              br(), br(),
              uiOutput("ajuste_mejor_modelo")
          ),
          box(title = tagList(icon("ranking-star"), " Comparativa AIC / BIC"),
              status = "primary", solidHeader = TRUE, width = 7,
              DTOutput("tabla_aic_bic"),
              br(),
              plotlyOutput("graf_aic_bic", height = "220px"))
        ),
        fluidRow(
          box(title = tagList(icon("chart-area"), " Funcion de Confiabilidad R(t) — Weibull vs. Exponencial"),
              status = "info", solidHeader = TRUE, width = 12,
              plotlyOutput("graf_rt_comparativo", height = "300px"))
        )
      ),

      # ════════ INTERVALO OPTIMO DE MANTENIMIENTO ═════════
      tabItem(tabName = "mantenimiento",
        fluidRow(
          box(title = tagList(icon("screwdriver-wrench"), " Parametros de Costo"),
              status = "danger", solidHeader = TRUE, width = 4,
              numericInput("mt_beta", "Beta (forma) ajustado:", value = 1.64, min = 0.1, step = 0.01),
              numericInput("mt_eta",  "Eta (escala, horas) ajustado:", value = 279.3, min = 1, step = 0.1),
              numericInput("mt_cp", "Costo Mantenimiento Preventivo (USD):", value = 500, min = 1),
              numericInput("mt_cf", "Costo de Falla Catastrofica (USD):", value = 3500, min = 1),
              br(),
              actionButton("btn_calc_mtto", "Calcular Intervalo Optimo",
                           class = "btn btn-danger btn-lg", icon = icon("calculator"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("chart-line"), " Costo Esperado vs. Intervalo de Mantenimiento"),
              status = "primary", solidHeader = TRUE, width = 8,
              uiOutput("mtto_resultados"),
              br(),
              plotlyOutput("mtto_grafico", height = "280px"))
        ),
        fluidRow(
          box(title = tagList(icon("table"), " Historial de Calculos de Mantenimiento Optimo"),
              status = "success", solidHeader = TRUE, width = 12,
              DTOutput("tabla_mantenimientos"))
        )
      ),

      # ════════ AMEF ═══════════════════════════════════════
      tabItem(tabName = "amef",
        fluidRow(
          box(title = tagList(icon("clipboard-list"), " Registrar Modo de Falla (AMEF)"),
              status = "danger", solidHeader = TRUE, width = 5,
              textInput("amef_modo", "Modo de Falla:", placeholder = "Ej: Fuga de sello principal"),
              textInput("amef_efecto", "Efecto de la Falla:", placeholder = "Ej: Perdida de fluido"),
              selectInput("amef_subsis", "Subsistema:", choices = SUBSISTEMAS_NOMBRES),
              sliderInput("amef_s", "Severidad (S):", min = 1, max = 10, value = 5),
              sliderInput("amef_o", "Ocurrencia (O):", min = 1, max = 10, value = 5),
              sliderInput("amef_d", "Deteccion (D):", min = 1, max = 10, value = 5),
              uiOutput("amef_npr_preview"),
              textAreaInput("amef_accion", "Accion Recomendada:", rows = 2),
              br(),
              actionButton("btn_agregar_amef", "Guardar Modo de Falla",
                           class = "btn btn-danger btn-lg", icon = icon("save"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("ranking-star"), " Numero de Prioridad de Riesgo por Modo"),
              status = "warning", solidHeader = TRUE, width = 7,
              plotlyOutput("graf_npr", height = "320px"))
        ),
        fluidRow(
          box(title = tagList(icon("table-list"), " Tabla AMEF Completa"),
              status = "primary", solidHeader = TRUE, width = 12,
              DTOutput("tabla_amef"))
        )
      ),

      # ════════ REPORTE PDF ════════════════════════════════
      tabItem(tabName = "rep_pdf",
        fluidRow(
          box(title = tagList(icon("file-pdf"), " Configurar Reporte de Confiabilidad"),
              status = "danger", solidHeader = TRUE, width = 5,
              textInput("rep_proyecto",   "Nombre del Proyecto:",
                        value = "Analisis de Confiabilidad Termo-Hidraulica"),
              textInput("rep_institucion","Institucion:", value = "FICCT - UAGRM"),
              textInput("rep_tutor",      "Tutor / Responsable:", value = ""),
              selectInput("rep_mes", "Mes del Reporte:",
                choices = setNames(1:12, c("Enero","Febrero","Marzo","Abril","Mayo","Junio",
                                            "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre")),
                selected = as.integer(format(Sys.Date(), "%m"))),
              numericInput("rep_anio", "Año:", value = as.integer(format(Sys.Date(), "%Y")), min = 2000),
              br(),
              downloadButton("btn_gen_pdf",
                             label = tagList(icon("file-pdf"), " Generar y Descargar PDF"),
                             class = "btn btn-danger dl-btn")
          ),
          box(title = tagList(icon("eye"), " Vista Previa del Reporte"),
              status = "info", solidHeader = TRUE, width = 7,
              uiOutput("preview_reporte"))
        )
      ),

      # ════════ EXPORTAR EXCEL ═════════════════════════════
      tabItem(tabName = "rep_excel",
        fluidRow(
          box(title = tagList(icon("file-excel"), " Exportar a Excel"),
              status = "success", solidHeader = TRUE, width = 5,
              p(style = "color:#374151;font-size:13px;line-height:1.7;",
                "Exporta el registro historico de fallas, el AMEF, los resultados de simulacion ",
                "Monte Carlo y el analisis de mantenimiento optimo a un archivo Excel con formato profesional."),
              tags$ul(style = "color:#64748b;font-size:12px;padding-left:16px;margin-bottom:16px;",
                tags$li("Hoja 1: Registro historico de TBF"),
                tags$li("Hoja 2: AMEF y Numero de Prioridad de Riesgo"),
                tags$li("Hoja 3: Resultados de simulaciones Monte Carlo"),
                tags$li("Hoja 4: Resumen de confiabilidad y mantenimiento optimo")
              ),
              br(),
              downloadButton("btn_gen_excel",
                             label = tagList(icon("file-excel"), " Generar y Descargar Excel"),
                             class = "btn btn-success dl-btn")
          ),
          box(title = tagList(icon("chart-bar"), " Vista Previa Excel"),
              status = "warning", solidHeader = TRUE, width = 7,
              uiOutput("preview_excel"))
        )
      ),

      # ════════ GESTION DE USUARIOS (solo Administrador) ══
      tabItem(tabName = "usuarios",
        fluidRow(
          box(title = tagList(icon("user-plus"), " Registrar Nuevo Usuario"),
              status = "info", solidHeader = TRUE, width = 5,
              textInput("us_usuario", "Nombre de Usuario:"),
              passwordInput("us_clave", "Contrasena:"),
              textInput("us_nombre", "Nombre Completo:"),
              selectInput("us_rol", "Rol:", choices = c("Administrador", "Analista")),
              br(),
              actionButton("btn_agregar_usuario", "Crear Usuario",
                           class = "btn btn-info btn-lg", icon = icon("user-plus"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("users"), " Usuarios del Sistema"),
              status = "primary", solidHeader = TRUE, width = 7,
              DTOutput("tabla_usuarios"))
        )
      ),

      # ════════ CONFIGURACION ══════════════════════════════
      tabItem(tabName = "config",
        fluidRow(
          box(title = tagList(icon("cog"), " Configuracion del Sistema"),
              status = "info", solidHeader = TRUE, width = 6,
              textInput("cfg_proyecto",   "Nombre del Proyecto:",
                        value = "Analisis Descriptivo y Modelado Probabilistico de Fallas en un Sistema Termo-Hidraulico de Amortiguacion"),
              textInput("cfg_institucion","Institucion:", value = "FICCT - UAGRM"),
              textInput("cfg_categoria",  "Categoria:", value = "Nivel Avanzado"),
              textInput("cfg_tutor",      "Tutor:", value = "MSc. Ing. Diego Antequera Virhuez"),
              textAreaInput("cfg_descripcion", "Descripcion del Proyecto:", rows = 3,
                value = "Sistema de analisis descriptivo y modelado probabilistico de fallas, con estimacion de confiabilidad MTBF/R(t)/h(t), AMEF y simulacion Monte Carlo."),
              br(),
              actionButton("btn_guardar_cfg", "Guardar Configuracion",
                           class = "btn btn-primary", icon = icon("save"),
                           style = "width:100%;")
          ),
          box(title = tagList(icon("info-circle"), " Acerca del Sistema"),
              status = "warning", solidHeader = TRUE, width = 6,
              div(style = "text-align:center;padding:20px;",
                icon("temperature-high", style = "font-size:60px;color:#0e7c66;"),
                h3(style = "color:#0b2e3d;font-weight:700;margin-top:12px;",
                   "Sistema de Confiabilidad"),
                h4(style = "color:#0e7c66;", "Termo-Hidraulico de Amortiguacion"),
                p(style = "color:#64748b;font-size:13px;line-height:1.7;margin-top:12px;",
                  "Sistema completo de analisis probabilistico de fallas. Integra estadistica ",
                  "descriptiva, ajuste de distribuciones de vida (Exponencial, Weibull, Normal, Gamma), ",
                  "calculo de MTBF/R(t)/h(t), AMEF, simulacion Monte Carlo y optimizacion del intervalo ",
                  "de mantenimiento preventivo."),
                hr(),
                p(style = "color:#94a3b8;font-size:11px;",
                  "Desarrollado para FICCT — UAGRM | Feria Facultativa 1/2026"),
                p(style = "color:#94a3b8;font-size:11px;",
                  "Probabilidad 1 & 2 | Metodos Numericos")
              )
          )
        )
      )
    )
  )
)

# ------------------------------------------------------------
# UI FINAL exportada a Shiny — conmuta entre login y dashboard
# segun el estado de autenticacion (ver server.R: pagina_principal)
# ------------------------------------------------------------
ui <- fluidPage(
  tags$head(tags$title("Confiabilidad Termo-Hidraulica — FICCT/UAGRM")),
  uiOutput("pagina_principal")
)
