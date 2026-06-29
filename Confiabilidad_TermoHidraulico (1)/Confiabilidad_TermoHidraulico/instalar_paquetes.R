# ============================================================
# instalar_paquetes.R
# Ejecutar este script UNA VEZ antes de abrir la aplicacion,
# si alguno de los paquetes necesarios no esta instalado.
#
# Uso en RStudio:
#   source("instalar_paquetes.R")
# ============================================================

paquetes_necesarios <- c(
  "shiny",          # Framework principal de la aplicacion web
  "shinydashboard", # Layout de dashboard (sidebar, valueBox, box)
  "DT",             # Tablas interactivas
  "ggplot2",        # Graficos estaticos
  "plotly",         # Graficos interactivos
  "openxlsx",       # Exportacion a Excel
  "rmarkdown",      # Generacion de reportes PDF
  "dplyr",          # Manipulacion de datos
  "DBI",            # Interfaz de base de datos
  "RSQLite",        # Motor de base de datos SQLite (sin servidor externo)
  "fitdistrplus"    # Ajuste de distribuciones por Maxima Verosimilitud
)

faltantes <- paquetes_necesarios[!paquetes_necesarios %in% rownames(installed.packages())]

if (length(faltantes) > 0) {
  cat("Instalando paquetes faltantes:", paste(faltantes, collapse = ", "), "\n")
  install.packages(faltantes, repos = "https://cloud.r-project.org")
} else {
  cat("Todos los paquetes necesarios ya estan instalados.\n")
}

# ------------------------------------------------------------
# OPCIONAL: para generar reportes PDF se necesita una
# distribucion de LaTeX. Si no la tiene, descomente la linea
# siguiente para instalar una version ligera (tinytex):
#
# if (!requireNamespace("tinytex", quietly = TRUE)) install.packages("tinytex")
# tinytex::install_tinytex()
#
# Si no instala LaTeX, el sistema generara automaticamente un
# PDF simplificado de respaldo (no requiere ninguna accion).
# ------------------------------------------------------------

cat("\nListo. Ahora puede abrir 'Confiabilidad_TermoHidraulico.Rproj' en RStudio\n")
cat("y presionar el boton 'Run App' (o abrir ui.R / server.R y ejecutar runApp()).\n")
