# Sistema de Análisis de Confiabilidad Termo-Hidráulica

Aplicación web desarrollada en **R Shiny** para el proyecto de feria:

> **Análisis Descriptivo y Modelado Probabilístico de Fallas en un Sistema Termo-Hidráulico de Amortiguación**
> FICCT — UAGRM | Probabilidad 1 & 2 / Métodos Numéricos | Feria Facultativa 1/2026

---

## 📋 ¿Qué hace esta aplicación?

Permite registrar y analizar los **tiempos entre fallas (TBF)** de un sistema termo-hidráulico
de amortiguación (compuesto por tres subsistemas: **Sellos**, **Fluido Hidráulico** y
**Mecánico**), y calcular automáticamente:

- Estadística descriptiva de los TBF (media, mediana, CV, etc.)
- Ajuste de distribuciones de vida (**Exponencial, Weibull, Normal, Gamma**) por Máxima
  Verosimilitud, comparadas mediante **AIC/BIC**.
- Funciones de **Confiabilidad R(t)**, **tasa de falla h(t)** y **MTBF**.
- **Curva de la bañera** (bathtub curve) por subsistema.
- **AMEF** (Análisis de Modos y Efectos de Falla) con cálculo automático del **NPR**.
- **Simulación Monte Carlo** del sistema en serie (N configurable).
- **Intervalo óptimo de mantenimiento preventivo** (minimización de costo esperado, con
  integración numérica por Regla de Simpson).
- Generación de **reportes en PDF** y **exportación a Excel**.
- Panel de **administración de usuarios** con dos roles: Administrador y Analista.

---

## 🗂️ Estructura del proyecto

```
Confiabilidad_TermoHidraulico/
├── Confiabilidad_TermoHidraulico.Rproj   ← abrir este archivo en RStudio
├── global.R           ← librerías, datos de prueba, funciones de cálculo
├── ui.R               ← interfaz de usuario (login + dashboard)
├── server.R           ← lógica del servidor
├── database.R         ← capa de acceso a datos (SQLite)
├── instalar_paquetes.R← instala automáticamente las dependencias necesarias
├── www/               ← recursos estáticos (logo)
├── confiabilidad.db   ← base de datos SQLite (se crea sola al ejecutar la app)
└── README.md
```

---

## ▶️ Cómo ejecutar la aplicación

1. Abra **RStudio**.
2. Abra el archivo `Confiabilidad_TermoHidraulico.Rproj` (esto fija el directorio de trabajo
   automáticamente — muy importante para que la base de datos SQLite se cree en la ruta correcta).
3. Si es la primera vez, ejecute en la consola:
   ```r
   source("instalar_paquetes.R")
   ```
   Esto instalará automáticamente todos los paquetes necesarios (`shiny`, `shinydashboard`,
   `DT`, `ggplot2`, `plotly`, `openxlsx`, `rmarkdown`, `dplyr`, `DBI`, `RSQLite`,
   `fitdistrplus`).
4. Abra el archivo `ui.R` o `server.R`.
5. Presione el botón **"Run App"** (esquina superior derecha del editor) — o ejecute en la
   consola:
   ```r
   shiny::runApp()
   ```

> La aplicación también puede generarse y reinstalarse desde cero sin problema: si borra el
> archivo `confiabilidad.db`, al volver a ejecutar la app se recreará automáticamente con
> todos los datos de prueba.

---

## 🔑 Credenciales de acceso (datos de prueba)

| Usuario     | Contraseña       | Rol            |
|-------------|------------------|----------------|
| `admin`     | `Admin2026@`     | Administrador  |
| `analista`  | `Analista2026@`  | Analista       |

El rol **Administrador** tiene acceso completo (subsistemas, mantenimiento óptimo, usuarios,
configuración). El rol **Analista** tiene acceso operativo (dashboard, registro de fallas,
ajuste de distribuciones, simulación, AMEF).

> El sistema de autenticación es propio (tabla `usuarios` en SQLite) y no depende de ningún
> archivo externo ni de paquetes adicionales de credenciales — funciona de inmediato.

---

## 🧮 Notas técnicas

- La base de datos se gestiona con **SQLite** a través de `DBI` + `RSQLite`, por lo que no
  requiere instalar ni configurar ningún servidor de base de datos externo.
- El cálculo de distribuciones de vida usa el paquete `fitdistrplus` (Máxima Verosimilitud).
- La generación de PDF usa `rmarkdown`. Si su equipo no tiene una distribución de LaTeX
  instalada, el sistema generará automáticamente un PDF simplificado de respaldo (no se
  requiere ninguna acción adicional). Para reportes con formato completo, puede instalar
  **TinyTeX** ejecutando:
  ```r
  install.packages("tinytex")
  tinytex::install_tinytex()
  ```
- Todos los datos mostrados al iniciar la aplicación por primera vez son **datos de prueba**
  basados en el proyecto de feria original (20 registros históricos de TBF, 3 subsistemas,
  7 modos de falla AMEF, 2 usuarios).

---

## 👥 Integrantes del proyecto original

- Azurduy Zambrana Ángel Moisés — Ing. Sistemas
- Villarroel Rocha Jhoel Arturo — Ing. Sistemas
- Montenegro Niño de Guzmán Derek — Ing. Redes
- Magne Manzano Víctor Alejandro — Ing. Sistemas
- Bulacia Vaca Yoel — Ing. Informática

**Tutores:** MSc. Ing. Diego Antequera Virhuez / MSc. Ing. Miguel Ángel Guthrie Pacheco

Santa Cruz de la Sierra — Bolivia, 2026
