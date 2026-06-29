# ============================================================
# global.R — Configuracion global, datos de prueba y funciones
# de calculo de confiabilidad (Weibull / Exponencial / MTBF)
# SISTEMA DE ANALISIS DE CONFIABILIDAD TERMO-HIDRAULICA
# FICCT - UAGRM
# ============================================================

paquetes <- c("shiny","shinydashboard","DT","ggplot2","plotly",
              "openxlsx","rmarkdown","dplyr","DBI","RSQLite","fitdistrplus")

invisible(lapply(paquetes, function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}))

library(shiny)
library(shinydashboard)
source("database.R")
library(DT)
library(ggplot2)
library(plotly)
library(openxlsx)
library(rmarkdown)
library(dplyr)
library(DBI)
library(RSQLite)
library(fitdistrplus)

source("database.R")
db_inicializar()

# ------------------------------------------------------------
# Helpers de formato
# ------------------------------------------------------------
hrs   <- function(x) paste0(formatC(as.numeric(x), format = "f", digits = 1, big.mark = ","), " h")
usd   <- function(x) paste0("USD ", formatC(as.numeric(x), format = "f", digits = 2, big.mark = ","))
pct   <- function(x) paste0(round(as.numeric(x), 1), "%")

mes_nombre <- function(m) c("Enero","Febrero","Marzo","Abril","Mayo","Junio",
  "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre")[as.integer(m)]

coalesce_str <- function(a, b) {
  if (is.null(a) || length(a) == 0) return(b)
  if (is.na(a[1]) || nchar(as.character(a[1])) == 0) return(b)
  a[1]
}

SUBSISTEMAS_NOMBRES <- c("Sellos", "Fluido Hidraulico", "Mecanico")
MODOS_FALLA <- c("Fuga de sello", "Degradacion de aceite", "Obstruccion de orificio",
                  "Corrosion interna", "Fatiga del piston", "Cavitacion",
                  "Sobrecalentamiento", "Falla estructural", "Otro")
SEVERIDADES <- c("Baja", "Media", "Alta", "Critica")

# ------------------------------------------------------------
# DATOS DE PRUEBA — Registro historico de fallas (TBF), tomado
# y ampliado a partir del proyecto de feria (20 obs. base)
# ------------------------------------------------------------
fallas_inicial <- data.frame(
  fecha = as.character(seq(as.Date("2025-01-10"), by = 14, length.out = 20)),
  tbf = c(120, 85, 340, 210, 95, 460, 175, 88, 520, 305,
          142, 67, 390, 225, 110, 480, 158, 73, 445, 280),
  subsistema = c("Sellos","Fluido Hidraulico","Fluido Hidraulico","Mecanico","Sellos",
                 "Mecanico","Fluido Hidraulico","Sellos","Mecanico","Fluido Hidraulico",
                 "Fluido Hidraulico","Sellos","Mecanico","Fluido Hidraulico","Sellos",
                 "Mecanico","Fluido Hidraulico","Sellos","Mecanico","Fluido Hidraulico"),
  modo_falla = c("Fuga de sello","Degradacion de aceite","Obstruccion de orificio","Corrosion interna",
                 "Fuga de sello","Fatiga del piston","Degradacion de aceite","Fuga de sello",
                 "Fatiga del piston","Cavitacion","Degradacion de aceite","Fuga de sello",
                 "Corrosion interna","Obstruccion de orificio","Fuga de sello","Fatiga del piston",
                 "Sobrecalentamiento","Fuga de sello","Corrosion interna","Degradacion de aceite"),
  severidad = c("Alta","Media","Media","Alta","Alta","Critica","Media","Alta","Critica","Media",
                "Media","Alta","Alta","Media","Alta","Critica","Media","Alta","Alta","Media"),
  censurado = rep(0, 20),
  observaciones = c("Reemplazo de sello principal","Cambio de aceite hidraulico","Limpieza de filtro",
                     "Tratamiento anticorrosivo","Sello secundario","Reemplazo de piston",
                     "Cambio de aceite","Sello principal","Reemplazo de piston","Purga de aire",
                     "Cambio de aceite","Sello secundario","Tratamiento anticorrosivo",
                     "Limpieza de filtro","Sello principal","Reemplazo de piston",
                     "Revision termica","Sello secundario","Tratamiento anticorrosivo","Cambio de aceite"),
  registrado_por = rep("admin", 20),
  stringsAsFactors = FALSE
)
db_insertar_fallas_iniciales(fallas_inicial)

# ------------------------------------------------------------
# DATOS DE PRUEBA — Subsistemas (parametros Weibull ajustados)
# ------------------------------------------------------------
subsistemas_inicial <- data.frame(
  nombre = c("Sellos", "Fluido Hidraulico", "Mecanico"),
  descripcion = c(
    "Sellos y empaques que contienen el fluido hidraulico bajo presion.",
    "Aceite/fluido hidraulico responsable de la transferencia de calor y amortiguacion.",
    "Conjunto piston-cilindro y componentes mecanicos de desplazamiento."
  ),
  beta = c(2.1, 1.8, 3.2),
  eta  = c(400, 350, 500),
  stringsAsFactors = FALSE
)
db_insertar_subsistemas_iniciales(subsistemas_inicial)

# ------------------------------------------------------------
# DATOS DE PRUEBA — AMEF (Analisis de Modos y Efectos de Falla)
# ------------------------------------------------------------
amef_inicial <- data.frame(
  fecha = rep(as.character(Sys.Date() - 30), 7),
  modo_falla = c("Fuga de sellos","Degradacion del aceite","Obstruccion de orificio",
                 "Corrosion interna","Fatiga del piston","Cavitacion","Sobrecalentamiento"),
  efecto = c("Perdida de fluido, falla total","Perdida de amortiguacion","Reduccion de flujo",
             "Desgaste acelerado","Fractura, falla subita","Dano por erosion","Degradacion acelerada"),
  subsistema = c("Sellos","Fluido Hidraulico","Fluido Hidraulico","Mecanico","Mecanico",
                 "Fluido Hidraulico","Fluido Hidraulico"),
  severidad = c(9, 7, 6, 8, 10, 7, 8),
  ocurrencia = c(7, 8, 5, 4, 3, 5, 6),
  deteccion = c(4, 5, 6, 7, 8, 5, 4),
  accion_recomendada = c(
    "Inspeccion periodica de sellos cada 150h","Monitoreo de viscosidad del aceite",
    "Limpieza programada de filtros","Recubrimiento anticorrosivo preventivo",
    "Analisis de vibraciones predictivo","Control de presion y purgado de aire",
    "Sensor de temperatura con alarma temprana"),
  stringsAsFactors = FALSE
)
db_insertar_amef_iniciales(amef_inicial)

# ------------------------------------------------------------
# DATOS DE PRUEBA — Usuarios del sistema (login propio)
# ------------------------------------------------------------
usuarios_inicial <- data.frame(
  usuario = c("admin", "analista"),
  clave   = c("Admin2026@", "Analista2026@"),
  nombre_completo = c("Administrador del Sistema", "Analista de Confiabilidad"),
  rol = c("Administrador", "Analista"),
  stringsAsFactors = FALSE
)
db_insertar_usuarios_iniciales(usuarios_inicial)

cfg_ini <- db_config_cargar()

# ============================================================
# FUNCIONES DE CONFIABILIDAD
# ============================================================

# --- Funcion de confiabilidad generica R(t) ---
confiabilidad <- function(t, dist = "weibull", ...) {
  switch(dist,
    "exp"     = pexp(t, ..., lower.tail = FALSE),
    "weibull" = pweibull(t, ..., lower.tail = FALSE),
    "norm"    = pnorm(t, ..., lower.tail = FALSE),
    "gamma"   = pgamma(t, ..., lower.tail = FALSE)
  )
}

confiabilidad_weibull <- function(t, beta, eta) exp(-(t / eta) ^ beta)
tasa_falla_weibull     <- function(t, beta, eta) (beta / eta) * (t / eta) ^ (beta - 1)
calcular_mtbf_weibull  <- function(beta, eta) eta * gamma(1 + 1 / beta)

# --- MTBF mediante integracion numerica (regla del trapecio) ---
calcular_mtbf_numerico <- function(dist = "weibull", t_max = 5000, n = 5000, ...) {
  t_seq <- seq(0, t_max, length.out = n)
  R_t <- confiabilidad(t_seq, dist, ...)
  mean(diff(t_seq)) * (sum(R_t[-1]) + sum(R_t[-n])) / 2
}

# --- Ajuste de distribuciones de vida por Maxima Verosimilitud ---
ajustar_distribuciones <- function(tbf, distribuciones = c("exp", "weibull", "norm", "gamma")) {
  resultados <- list()
  for (dist in distribuciones) {
    tryCatch({
      fit <- fitdist(tbf, dist)
      resultados[[dist]] <- list(
        parametros = fit$estimate,
        aic = fit$aic,
        bic = fit$bic,
        loglik = fit$loglik
      )
    }, error = function(e) NULL)
  }
  aics <- sapply(resultados, function(x) x$aic)
  resultados[order(aics)]
}

nombre_dist <- function(d) switch(d,
  "exp" = "Exponencial", "weibull" = "Weibull", "norm" = "Normal", "gamma" = "Gamma", d)

# --- Integral de R(t) en [0, tp] por Regla de Simpson compuesta ---
integral_simpson <- function(tp, beta, eta, n = 1000) {
  if (n %% 2 != 0) n <- n + 1
  t_seq <- seq(0, tp, length.out = n + 1)
  R_t <- confiabilidad_weibull(t_seq, beta, eta)
  h <- tp / n
  (h / 3) * (R_t[1] + R_t[n + 1] +
             4 * sum(R_t[seq(2, n, by = 2)]) +
             2 * sum(R_t[seq(3, n - 1, by = 2)]))
}

# --- Costo esperado de mantenimiento por unidad de tiempo ---
costo_mantenimiento <- function(tp, beta, eta, cp, cf) {
  Rtp  <- confiabilidad_weibull(tp, beta, eta)
  intR <- integral_simpson(tp, beta, eta)
  (cp * Rtp + cf * (1 - Rtp)) / (tp * Rtp + intR)
}

# --- Busqueda del intervalo optimo de mantenimiento preventivo ---
intervalo_optimo_mantenimiento <- function(beta, eta, cp, cf, t_min = 10, t_max = 800) {
  t_seq <- seq(t_min, t_max, by = 1)
  costos <- sapply(t_seq, costo_mantenimiento, beta = beta, eta = eta, cp = cp, cf = cf)
  t_opt <- t_seq[which.min(costos)]
  costo_opt <- min(costos)
  costo_reactivo <- cf * tasa_falla_weibull(calcular_mtbf_weibull(beta, eta), beta, eta)
  ahorro <- if (costo_reactivo > 0) (1 - costo_opt / costo_reactivo) * 100 else 0
  list(t_seq = t_seq, costos = costos, t_optimo = t_opt,
       costo_optimo = costo_opt, ahorro_pct = max(0, ahorro))
}

# --- Simulacion Monte Carlo del sistema en serie ---
simulacion_montecarlo <- function(params, N = 10000, semilla = 2026) {
  set.seed(semilla)
  tiempos_falla <- matrix(NA, nrow = N, ncol = length(params))
  colnames(tiempos_falla) <- names(params)
  for (i in seq_along(params)) {
    p <- params[[i]]
    tiempos_falla[, i] <- rweibull(N, shape = p$beta, scale = p$eta)
  }
  t_sistema <- apply(tiempos_falla, 1, min)
  list(
    t_sistema      = t_sistema,
    mtbf_simulado  = mean(t_sistema),
    sd_simulado    = sd(t_sistema),
    percentil_10   = as.numeric(quantile(t_sistema, 0.10)),
    percentil_50   = as.numeric(quantile(t_sistema, 0.50)),
    confiabilidad  = function(t) mean(t_sistema > t)
  )
}

# --- AIC / BIC tabla resumen ---
tabla_aic_bic <- function(fits) {
  if (length(fits) == 0) return(data.frame())
  data.frame(
    Distribucion = sapply(names(fits), nombre_dist),
    AIC = sapply(fits, function(x) round(x$aic, 2)),
    BIC = sapply(fits, function(x) round(x$bic, 2)),
    LogLik = sapply(fits, function(x) round(x$loglik, 2)),
    stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------
# Tema visual para ggplot2 (graficos estaticos / preview PDF)
# ------------------------------------------------------------
tema_corp <- theme_minimal(base_size = 11) +
  theme(
    plot.background  = element_rect(fill = "#ffffff", color = NA),
    panel.background = element_rect(fill = "#f8fafc", color = "#e2e8f0", linewidth = 0.4),
    panel.grid.major = element_line(color = "#f1f5f9", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(color = "#374151", size = 9),
    axis.title       = element_text(color = "#111827", size = 10, face = "bold"),
    plot.title       = element_text(color = "#111827", size = 12, face = "bold", margin = margin(b = 4)),
    plot.subtitle    = element_text(color = "#6b7280", size = 9, margin = margin(b = 6)),
    legend.position  = "bottom",
    legend.text      = element_text(size = 9, color = "#374151"),
    legend.title     = element_blank(),
    plot.margin      = margin(12, 16, 12, 16)
  )

cat("[SISTEMA] Modulo de confiabilidad termo-hidraulica listo.\n")
