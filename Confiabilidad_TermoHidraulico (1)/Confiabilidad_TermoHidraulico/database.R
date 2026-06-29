# ============================================================
# database.R — Capa de acceso a datos (SQLite)
# SISTEMA DE ANALISIS DE CONFIABILIDAD TERMO-HIDRAULICA
# FICCT - UAGRM | Probabilidad 1 & 2 / Metodos Numericos
# ============================================================

library(DBI)
library(RSQLite)

DB_PATH <- "confiabilidad.db"

db_con <- function() dbConnect(RSQLite::SQLite(), DB_PATH)

# ------------------------------------------------------------
# Inicializacion de esquema
# ------------------------------------------------------------
db_inicializar <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))

  # Registro historico de tiempos entre fallas (TBF)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS fallas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    tbf REAL NOT NULL,
    subsistema TEXT NOT NULL DEFAULT 'Mecanico',
    modo_falla TEXT NOT NULL DEFAULT 'No especificado',
    severidad TEXT NOT NULL DEFAULT 'Media',
    censurado INTEGER NOT NULL DEFAULT 0,
    observaciones TEXT DEFAULT '',
    registrado_por TEXT DEFAULT 'sistema'
  )")

  # Subsistemas del sistema termo-hidraulico (parametros Weibull)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS subsistemas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT DEFAULT '',
    beta REAL NOT NULL DEFAULT 1.5,
    eta REAL NOT NULL DEFAULT 300,
    activo INTEGER NOT NULL DEFAULT 1
  )")

  # AMEF: modos de falla y numero de prioridad de riesgo
  dbExecute(con, "CREATE TABLE IF NOT EXISTS amef (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    modo_falla TEXT NOT NULL,
    efecto TEXT NOT NULL DEFAULT '',
    subsistema TEXT NOT NULL DEFAULT 'Mecanico',
    severidad INTEGER NOT NULL DEFAULT 5,
    ocurrencia INTEGER NOT NULL DEFAULT 5,
    deteccion INTEGER NOT NULL DEFAULT 5,
    npr REAL NOT NULL DEFAULT 0,
    accion_recomendada TEXT DEFAULT ''
  )")

  # Resultados de simulaciones Monte Carlo guardadas
  dbExecute(con, "CREATE TABLE IF NOT EXISTS simulaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    n_replicas INTEGER NOT NULL DEFAULT 10000,
    mtbf_simulado REAL NOT NULL,
    sd_simulado REAL NOT NULL,
    p10 REAL NOT NULL,
    p50 REAL NOT NULL,
    r150 REAL NOT NULL,
    r250 REAL NOT NULL,
    r400 REAL NOT NULL,
    semilla INTEGER NOT NULL DEFAULT 2026,
    ejecutado_por TEXT DEFAULT 'sistema'
  )")

  # Ajustes de mantenimiento preventivo calculados
  dbExecute(con, "CREATE TABLE IF NOT EXISTS mantenimiento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    beta REAL NOT NULL,
    eta REAL NOT NULL,
    costo_preventivo REAL NOT NULL,
    costo_correctivo REAL NOT NULL,
    t_optimo REAL NOT NULL,
    costo_optimo REAL NOT NULL,
    ahorro_pct REAL NOT NULL DEFAULT 0
  )")

  # Usuarios del sistema (login propio, sin dependencias externas)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario TEXT NOT NULL UNIQUE,
    clave TEXT NOT NULL,
    nombre_completo TEXT NOT NULL DEFAULT '',
    rol TEXT NOT NULL DEFAULT 'Analista',
    activo INTEGER NOT NULL DEFAULT 1,
    creado TEXT DEFAULT ''
  )")

  # Configuracion general del sistema (clave/valor)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS configuracion (
    clave TEXT PRIMARY KEY,
    valor TEXT
  )")

  cat("[DB] Inicializada:", normalizePath(DB_PATH, mustWork = FALSE), "\n")
}

# ------------------------------------------------------------
# FALLAS (TBF)
# ------------------------------------------------------------
db_insertar_fallas_iniciales <- function(df) {
  con <- db_con(); on.exit(dbDisconnect(con))
  if (dbGetQuery(con, "SELECT COUNT(*) as n FROM fallas")$n > 0) return(invisible())
  for (i in seq_len(nrow(df))) {
    f <- df[i, ]
    dbExecute(con, "INSERT INTO fallas
      (fecha, tbf, subsistema, modo_falla, severidad, censurado, observaciones, registrado_por)
      VALUES (?,?,?,?,?,?,?,?)",
      list(f$fecha, f$tbf, f$subsistema, f$modo_falla, f$severidad,
           f$censurado, f$observaciones, f$registrado_por))
  }
  cat("[DB] Fallas iniciales insertadas:", nrow(df), "\n")
}

db_fallas <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM fallas ORDER BY id DESC")
}

db_nueva_falla <- function(fecha, tbf, subsistema, modo_falla, severidad,
                            censurado, observaciones, registrado_por = "sistema") {
  con <- db_con(); on.exit(dbDisconnect(con))
  tryCatch({
    dbExecute(con, "INSERT INTO fallas
      (fecha, tbf, subsistema, modo_falla, severidad, censurado, observaciones, registrado_por)
      VALUES (?,?,?,?,?,?,?,?)",
      list(as.character(fecha), tbf, subsistema, modo_falla, severidad,
           as.integer(censurado), observaciones, registrado_por))
    TRUE
  }, error = function(e) { cat("[DB ERROR]", conditionMessage(e), "\n"); FALSE })
}

db_eliminar_falla <- function(id) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "DELETE FROM fallas WHERE id=?", list(id))
}

# ------------------------------------------------------------
# SUBSISTEMAS
# ------------------------------------------------------------
db_insertar_subsistemas_iniciales <- function(df) {
  con <- db_con(); on.exit(dbDisconnect(con))
  if (dbGetQuery(con, "SELECT COUNT(*) as n FROM subsistemas")$n > 0) return(invisible())
  for (i in seq_len(nrow(df))) {
    s <- df[i, ]
    dbExecute(con, "INSERT OR IGNORE INTO subsistemas (nombre, descripcion, beta, eta)
      VALUES (?,?,?,?)", list(s$nombre, s$descripcion, s$beta, s$eta))
  }
  cat("[DB] Subsistemas iniciales insertados:", nrow(df), "\n")
}

db_subsistemas <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM subsistemas WHERE activo=1 ORDER BY nombre")
}

db_actualizar_subsistema <- function(id, beta, eta, descripcion) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "UPDATE subsistemas SET beta=?, eta=?, descripcion=? WHERE id=?",
            list(beta, eta, descripcion, id))
}

db_nuevo_subsistema <- function(nombre, descripcion, beta, eta) {
  con <- db_con(); on.exit(dbDisconnect(con))
  tryCatch({
    dbExecute(con, "INSERT INTO subsistemas (nombre, descripcion, beta, eta) VALUES (?,?,?,?)",
              list(nombre, descripcion, beta, eta))
    TRUE
  }, error = function(e) { cat("[DB ERROR]", conditionMessage(e), "\n"); FALSE })
}

# ------------------------------------------------------------
# AMEF
# ------------------------------------------------------------
db_insertar_amef_iniciales <- function(df) {
  con <- db_con(); on.exit(dbDisconnect(con))
  if (dbGetQuery(con, "SELECT COUNT(*) as n FROM amef")$n > 0) return(invisible())
  for (i in seq_len(nrow(df))) {
    a <- df[i, ]
    npr <- a$severidad * a$ocurrencia * a$deteccion
    dbExecute(con, "INSERT INTO amef
      (fecha, modo_falla, efecto, subsistema, severidad, ocurrencia, deteccion, npr, accion_recomendada)
      VALUES (?,?,?,?,?,?,?,?,?)",
      list(a$fecha, a$modo_falla, a$efecto, a$subsistema,
           a$severidad, a$ocurrencia, a$deteccion, npr, a$accion_recomendada))
  }
  cat("[DB] AMEF inicial insertado:", nrow(df), "\n")
}

db_amef <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM amef ORDER BY npr DESC")
}

db_nuevo_amef <- function(modo_falla, efecto, subsistema, severidad, ocurrencia, deteccion, accion) {
  con <- db_con(); on.exit(dbDisconnect(con))
  npr <- severidad * ocurrencia * deteccion
  tryCatch({
    dbExecute(con, "INSERT INTO amef
      (fecha, modo_falla, efecto, subsistema, severidad, ocurrencia, deteccion, npr, accion_recomendada)
      VALUES (?,?,?,?,?,?,?,?,?)",
      list(as.character(Sys.Date()), modo_falla, efecto, subsistema,
           severidad, ocurrencia, deteccion, npr, accion))
    TRUE
  }, error = function(e) { cat("[DB ERROR]", conditionMessage(e), "\n"); FALSE })
}

# ------------------------------------------------------------
# SIMULACIONES MONTE CARLO
# ------------------------------------------------------------
db_registrar_simulacion <- function(n_rep, mtbf_sim, sd_sim, p10, p50, r150, r250, r400,
                                     semilla, usuario = "sistema") {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "INSERT INTO simulaciones
    (fecha, n_replicas, mtbf_simulado, sd_simulado, p10, p50, r150, r250, r400, semilla, ejecutado_por)
    VALUES (?,?,?,?,?,?,?,?,?,?,?)",
    list(as.character(Sys.time()), n_rep, mtbf_sim, sd_sim, p10, p50, r150, r250, r400,
         semilla, usuario))
}

db_simulaciones <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM simulaciones ORDER BY id DESC LIMIT 200")
}

# ------------------------------------------------------------
# MANTENIMIENTO OPTIMO
# ------------------------------------------------------------
db_registrar_mantenimiento <- function(beta, eta, cp, cf, t_opt, costo_opt, ahorro) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "INSERT INTO mantenimiento
    (fecha, beta, eta, costo_preventivo, costo_correctivo, t_optimo, costo_optimo, ahorro_pct)
    VALUES (?,?,?,?,?,?,?,?)",
    list(as.character(Sys.time()), beta, eta, cp, cf, t_opt, costo_opt, ahorro))
}

db_mantenimientos <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM mantenimiento ORDER BY id DESC LIMIT 200")
}

# ------------------------------------------------------------
# USUARIOS (login propio)
# ------------------------------------------------------------
db_insertar_usuarios_iniciales <- function(df) {
  con <- db_con(); on.exit(dbDisconnect(con))
  if (dbGetQuery(con, "SELECT COUNT(*) as n FROM usuarios")$n > 0) return(invisible())
  for (i in seq_len(nrow(df))) {
    u <- df[i, ]
    dbExecute(con, "INSERT OR IGNORE INTO usuarios
      (usuario, clave, nombre_completo, rol, activo, creado)
      VALUES (?,?,?,?,1,?)",
      list(u$usuario, u$clave, u$nombre_completo, u$rol, as.character(Sys.Date())))
  }
  cat("[DB] Usuarios iniciales insertados:", nrow(df), "\n")
}

db_usuarios <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT id, usuario, nombre_completo, rol, activo, creado FROM usuarios ORDER BY id")
}

db_validar_login <- function(usuario, clave) {
  con <- db_con(); on.exit(dbDisconnect(con))
  df <- dbGetQuery(con, "SELECT * FROM usuarios WHERE usuario=? AND activo=1",
                    list(usuario))
  if (nrow(df) == 0) return(NULL)
  if (!identical(as.character(df$clave[1]), as.character(clave))) return(NULL)
  df[1, ]
}

db_nuevo_usuario <- function(usuario, clave, nombre_completo, rol) {
  con <- db_con(); on.exit(dbDisconnect(con))
  tryCatch({
    dbExecute(con, "INSERT INTO usuarios (usuario, clave, nombre_completo, rol, activo, creado)
      VALUES (?,?,?,?,1,?)",
      list(usuario, clave, nombre_completo, rol, as.character(Sys.Date())))
    TRUE
  }, error = function(e) { cat("[DB ERROR]", conditionMessage(e), "\n"); FALSE })
}

db_cambiar_estado_usuario <- function(id, activo) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "UPDATE usuarios SET activo=? WHERE id=?", list(as.integer(activo), id))
}

db_eliminar_usuario <- function(id) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "DELETE FROM usuarios WHERE id=?", list(id))
}

# ------------------------------------------------------------
# CONFIGURACION
# ------------------------------------------------------------
db_config_guardar <- function(clave, valor) {
  con <- db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, "INSERT OR REPLACE INTO configuracion(clave,valor) VALUES(?,?)",
            list(clave, as.character(valor)))
}

db_config_cargar <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  df <- dbGetQuery(con, "SELECT clave,valor FROM configuracion")
  if (nrow(df) == 0) return(list())
  as.list(setNames(df$valor, df$clave))
}

# ------------------------------------------------------------
# DASHBOARD — indicadores agregados
# ------------------------------------------------------------
db_dashboard <- function() {
  con <- db_con(); on.exit(dbDisconnect(con))
  list(
    n_fallas      = tryCatch(dbGetQuery(con, "SELECT COUNT(*) as v FROM fallas")$v, error = function(e) 0),
    mtbf_emp      = tryCatch(dbGetQuery(con, "SELECT COALESCE(AVG(tbf),0) as v FROM fallas")$v, error = function(e) 0),
    sd_emp        = tryCatch(dbGetQuery(con, "SELECT tbf FROM fallas")$tbf, error = function(e) numeric(0)),
    fallas_subsis = tryCatch(dbGetQuery(con, "SELECT subsistema, COUNT(*) as n, AVG(tbf) as mtbf FROM fallas GROUP BY subsistema ORDER BY n DESC"), error = function(e) data.frame()),
    fallas_modo   = tryCatch(dbGetQuery(con, "SELECT modo_falla, COUNT(*) as n FROM fallas GROUP BY modo_falla ORDER BY n DESC"), error = function(e) data.frame()),
    ultimas       = tryCatch(dbGetQuery(con, "SELECT fecha, tbf, subsistema, modo_falla, severidad FROM fallas ORDER BY id DESC LIMIT 10"), error = function(e) data.frame()),
    n_amef_alto   = tryCatch(dbGetQuery(con, "SELECT COUNT(*) as v FROM amef WHERE npr > 150")$v, error = function(e) 0),
    n_simulaciones= tryCatch(dbGetQuery(con, "SELECT COUNT(*) as v FROM simulaciones")$v, error = function(e) 0),
    ultima_sim    = tryCatch(dbGetQuery(con, "SELECT * FROM simulaciones ORDER BY id DESC LIMIT 1"), error = function(e) data.frame()),
    ultimo_mtto   = tryCatch(dbGetQuery(con, "SELECT * FROM mantenimiento ORDER BY id DESC LIMIT 1"), error = function(e) data.frame())
  )
}
