# Al inicio del script, antes de cargar librerías
options(repos = c(CRAN = "https://cloud.r-project.org"))
library(shiny)
library(shinydashboard)
library(shinyjs)
library(highcharter)
library(dplyr)
library(readxl)
library(DT)
library(stringr)
# ══════════════════════════════════════════════════════════════════════════════
# DATOS (Dic 2021 – Dic 2025, en Millones USD)
# ══════════════════════════════════════════════════════════════════════════════
years <- c(2021, 2022, 2023, 2024, 2025)

bp <- list(
  activo             = c(7049.88, 6990.58, 7005.27,  8691.87,  9877.22),
  pasivo             = c(6230.96, 6076.34, 6036.84,  7656.87,  8764.02),
  patrimonio         = c( 818.92,  914.24,  968.43,  1034.99,  1113.20),
  cartera_bruta      = c(4292.86, 4395.62, 4867.71,  5456.07,  6506.40),
  oblig_publico      = c(5471.71, 5349.01, 5479.65,  6834.76,  7847.57),
  oblig_financieras  = c( 485.81,  417.47,  225.04,   415.72,   517.03),
  cartera_pv         = c(3776.27, 4061.52, 4581.09,  5207.28,  6316.95),
  cartera_qndi       = c(  62.62,   84.49,  117.28,   130.71,   116.04),
  cartera_vencida    = c(  51.29,   59.00,   68.71,    57.68,    49.08),
  cartera_imp        = c( 113.91,  143.49,  185.99,   188.39,   165.12),
  c1499              = c( 260.02,  281.27,  331.12,   342.39,   402.84),
  ingresos           = c( 743.18,  787.05,  880.94, 1049.19, 1148.45),
  gastos             = c( 737.46,  678.85,  758.32,  891.13,  942.32),
  utilidad           = c(   5.72,  108.20,  122.62,  158.06,  206.13),
  mbf                = c( 446.03,  470.63,  504.76,  574.93,  648.17),
  gastos_op          = c( 290.06,  229.89,  220.16,  229.19,  274.81),
  roe                = c(  0.70,  11.84,  12.66,  15.27,  18.52),
  roa                = c(  0.08,   1.55,   1.75,   1.82,   2.09),
  eficiencia         = c( 65.03,  48.85,  43.62,  39.86,  42.40),
  liquidez           = c( 36.07,  33.24,  23.61,  26.46,  22.88),
  morosidad          = c(  2.65,   3.26,   3.82,   3.45,   2.54),
  cobertura          = c(228.27, 196.02, 178.03, 181.74, 243.97)
)
bp$intermediacion <- bp$cartera_bruta / bp$oblig_publico * 100

sis <- list(
  activo             = c(52398.65, 56885.55, 60758.60, 68924.83, 76653.59),
  pasivo             = c(46895.37, 50836.56, 54052.47, 61801.03, 68788.66),
  patrimonio         = c( 5503.28,  6048.99,  6706.13,  7123.80,  7864.93),
  cartera_bruta      = c(33660.28, 38589.48, 42129.29, 45934.37, 51557.78),
  oblig_publico      = c(41205.60, 43643.12, 46232.39, 53062.28, 60598.23),
  oblig_financieras  = c( 2772.21,  3628.36,  3872.26,  4813.21,  4186.63),
  cartera_pv         = c(32138.11, 37345.05, 40577.58, 44324.71, 49909.26),
  cartera_qndi       = c(  438.00,   541.54,   905.38,   974.95,  1023.83),
  cartera_vencida    = c(  214.59,   275.08,   422.33,   460.25,   486.84),
  cartera_imp        = c(  652.59,   816.61,  1327.71,  1435.19,  1510.67),
  c1499              = c( 2331.67,  2650.06,  2848.47,  3078.25,  3421.94),
  ingresos           = c(5362.83, 6138.09, 7301.75, 8263.87, 8733.46),
  gastos             = c(4975.48, 5474.38, 6564.24, 7603.67, 7787.02),
  utilidad           = c( 387.35,  663.71,  737.51,  660.20,  946.44),
  mbf                = c(3636.99, 4219.93, 4588.54, 4836.88, 5463.53),
  gastos_op          = c(2211.38, 2319.86, 2378.05, 2557.63, 2719.56),
  roe                = c(  7.04,  10.97,  11.00,   9.27,  12.03),
  roa                = c(  0.74,   1.17,   1.21,   0.96,   1.23),
  eficiencia         = c( 60.80,  54.97,  51.83,  52.88,  49.78),
  liquidez           = c( 28.62,  28.90,  24.13,  22.25,  20.25),
  morosidad          = c(  1.94,   2.12,   3.15,   3.12,   2.93),
  cobertura          = c(357.29, 324.52, 214.54, 214.48, 226.52)
)
sis$intermediacion <- sis$cartera_bruta / sis$oblig_publico * 100


# ══════════════════════════════════════════════════════════════════════════════
# DATOS DE COLOCACIONES GEOGRÁFICAS (desde Excel)
# ══════════════════════════════════════════════════════════════════════════════

# Ruta del archivo (ajústala según donde esté)
ruta_excel <- "volumen_agregado.xlsx"  # O la ruta completa

# Verificar si el archivo existe
if(file.exists(ruta_excel)) {
  datos_raw <- read_excel(ruta_excel, sheet = "Hoja1")
  names(datos_raw) <- c("ENTIDAD", "PROVINCIA", "MONTO_OTORGADO")
  
  datos_colocaciones <- datos_raw %>%
    mutate(
      MONTO_MM = MONTO_OTORGADO / 1000000,
      PROVINCIA_LIMPIA = case_when(
        PROVINCIA == "SANTO DOMINGO DE LOS TSÁCHILAS" ~ "Santo Domingo de los Tsachilas",
        PROVINCIA == "MORONA SANTIAGO" ~ "Morona-Santiago",
        PROVINCIA == "ZAMORA CHINCHIPE" ~ "Zamora-Chinchipe",
        PROVINCIA == "SANTA ELENA" ~ "Santa-Elena",
        PROVINCIA == "LOS RIOS" ~ "Los-Rios",
        PROVINCIA == "EL ORO" ~ "El-Oro",
        PROVINCIA == "GALAPAGOS" ~ "Galapagos",
        TRUE ~ PROVINCIA
      ),
      PROVINCIA_MAPA = str_to_title(PROVINCIA_LIMPIA)
    )
  
  bancos_disponibles <- sort(unique(datos_colocaciones$ENTIDAD))
  provincias_disponibles <- sort(unique(datos_colocaciones$PROVINCIA))
  
  totales_banco <- datos_colocaciones %>%
    group_by(ENTIDAD) %>%
    summarise(
      TOTAL_MM = sum(MONTO_MM, na.rm = TRUE),
      PROVINCIAS = n_distinct(PROVINCIA),
      PROVINCIA_PRINCIPAL = PROVINCIA[which.max(MONTO_MM)],
      MAX_MONTO = max(MONTO_MM, na.rm = TRUE)
    ) %>%
    arrange(desc(TOTAL_MM))
} else {
  # Datos de respaldo si no encuentra el archivo
  datos_colocaciones <- data.frame()
  bancos_disponibles <- c("BP PACIFICO", "BP GUAYAQUIL", "BP PICHINCHA")
  provincias_disponibles <- c("GUAYAS", "PICHINCHA", "AZUAY")
  totales_banco <- data.frame()
}

#==============================================================================#


# ── Helpers ──────────────────────────────────────────────────────────────────
var_abs <- function(x) c(NA, diff(x))
var_rel <- function(x) c(NA, diff(x) / head(x, -1) * 100)
pct     <- function(a, b) a / b * 100
fmt_n   <- function(x) formatC(round(x, 1), format = "f", digits = 1, big.mark = ",")

# ── Paleta ───────────────────────────────────────────────────────────────────
C <- list(
  bp1 = "#003087", bp2 = "#0054A6", bp3 = "#4A90D9",
  s1  = "#E8891D", s2  = "#F7C87E",
  grn = "#27AE60", red = "#C0392B", gry = "#95A5A6",
  bg  = "white"
)

# ── Funciones Highcharter ────────────────────────────────────────────────────
hc_base <- function(title = "", y_title = "Millones USD", is_pct = FALSE) {
  y_suffix <- if(is_pct) "%" else ""
  highchart() %>%
    hc_chart(backgroundColor = "white", style = list(fontFamily = "Segoe UI, Arial")) %>%
    hc_title(text = title, style = list(color = "#2C3E50", fontSize = "13px", fontWeight = "bold")) %>%
    hc_xAxis(categories = as.character(years), title = list(text = "")) %>%
    hc_yAxis(title = list(text = y_title), labels = list(format = paste0("{value}", y_suffix))) %>%
    hc_tooltip(shared = TRUE, valueDecimals = 1, valueSuffix = y_suffix) %>%
    hc_legend(align = "center", verticalAlign = "bottom", layout = "horizontal") %>%
    hc_plotOptions(series = list(marker = list(symbol = "circle", radius = 4)))
}

hc_line <- function(hc, y, name, color, dash = "solid") {
  dash_style <- if(dash == "dash") "Dash" else "Solid"
  hc %>%
    hc_add_series(name = name, data = round(y, 2), type = "line",
                  color = color, lineWidth = 2.5,
                  dashStyle = dash_style,
                  marker = list(radius = 5, fillColor = color, lineColor = "white", lineWidth = 1.5))
}

hc_column <- function(hc, y, name, color) {
  hc %>%
    hc_add_series(name = name, data = round(y, 2), type = "column",
                  color = color, borderColor = "white", borderWidth = 1)
}

hc_area <- function(hc, y, name, color) {
  hc %>%
    hc_add_series(name = name, data = round(y, 2), type = "area",
                  color = color, fillColor = paste0(color, "66"), lineWidth = 1.5,
                  marker = list(radius = 2))
}

# ── KPI card (estilo moderno) ────────────────────────────────────────────────
kpi_card <- function(lbl, val, vr = NULL, is_pct = FALSE) {
  disp <- if (is_pct) paste0(fmt_n(val), "%")
  else        paste0("$", fmt_n(val), " MM")
  vr_html <- if (!is.null(vr) && !is.na(vr)) {
    col <- if (vr >= 0) C$grn else C$red
    arr <- if (vr >= 0) "▲" else "▼"
    div(style = paste0("color:", col, ";font-size:11px;margin-top:6px;font-weight:500;"),
        paste(arr, round(vr, 1), "% vs año anterior"))
  }
  div(
    style = "
    background: white;
    border-radius:0px;
    padding:16px ;
    text-align:center;
    box-shadow:0 2px 8px rgba(0,0,0,0.06);
    height:100%;
    border-left:3px solid #003087;transition:all 0.2s;
    ",
    
    div(style = "font-size:22px;font-weight:800;color:#003087;letter-spacing:-0.5px;", disp),
    div(style = "font-size:12px;color:#5D6D7E;margin-top:6px;font-weight:500;text-transform:uppercase;", lbl),
    vr_html
  )
}
# #fff

custom_card <- function(title, subtitle = NULL, icon_name = NULL, ...) {
  icon_html <- if(!is.null(icon_name)) {
    div(style = "float:right;font-size:24px;color:#95a5a6;margin-top:2px;",
        icon(icon_name))
  } else { NULL }
  
  div(
    # Contenedor principal
    style = "background:#ffffff;
             border-radius:0px; 
             box-shadow:0 10px 25px rgba(0,0,0,0.1);
             margin-bottom:25px;
             position:relative; # IMPORTANTE para posicionar la línea
             overflow:hidden;
             transition:all 0.3s ease;
             border: 1px solid #f0f0f0;",
    
    # ESTA ES LA LÍNEA GRIS AL 50%
    div(style = "position:absolute; 
                 top:0; 
                 left:0; 
                 width:50%; # AQUÍ AJUSTAS EL LARGO
                 height:4px; 
                 background:#e0e0e0;"),
    
    # Cabecera (Se eliminó el border-top de aquí)
    div(
      style = "padding:18px 20px 10px 20px;
               background:#ffffff;",
      icon_html,
      div(style = "font-size:17px;font-weight:700;color:#2c3e50;letter-spacing:-0.5px;", title),
      if(!is.null(subtitle)) div(style = "font-size:12px;color:#95a5a6;margin-top:4px;", subtitle)
    ),
    
    # Cuerpo del contenedor
    div(style = "padding:10px 20px 25px 20px;", ...)
  )
}
# cargar logo en b64
log_b64 <- paste(readLines("logPac_b64.txt", warn = FALSE), collapse = "")
icon_b64 <- paste(readLines("icon_pacifico.txt", warn = FALSE), collapse = "")
  

  #### UI ####
  ui <- shinydashboard::dashboardPage(
    shinydashboard::dashboardHeader(
      title = tags$div(style = "font-size: 14px;","Análisis y Diseño Estratégico"),
      titleWidth = 280,
      tags$li(class = "dropdown",
              actionLink(inputId = "autor_btn",
                         label   = "Autor",
                         icon= icon("circle-info")
              )
      )
    ),
    
    dashboardSidebar(
      tags$head(tags$link(rel= "icon", 
                          href = icon_b64,
                          type= "image/png", height = "100px")
      ),
      # Centrar la imagen
      tags$div(style = "text-align: center; padding: 10px;",
               tags$img(src = log_b64, height = "auto", width = "85%")),
      
      shinydashboard::sidebarMenu(
        menuItem("Inicio", tabName = "inicio", 
                 icon = icon("home",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;")),
        
        menuItem("Cargar datos", tabName = "cargar", 
                 icon = icon("upload",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;")),
        
        
        menuItem("Balance General", tabName = "bg_dummy",
                 icon = icon("balance-scale",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;"),
                 
                 menuSubItem("Estructura Financiera",
                             icon = icon("circle",
                                         class = "fa-fw",
                                         style = "font-size:10px; width:20px; margin-right:2px; color:black;"),
                             tabName = "estructura"),
                 
                 menuSubItem("Intermediación Financiera",
                             icon = icon("circle",
                                         class = "fa-fw",
                                         style = "font-size:10px; width:20px; margin-right:2px; color:black;"),
                             tabName = "intermediacion"),
                 
                 menuSubItem("Calidad de Cartera",
                             icon = icon("circle",
                                         class = "fa-fw",
                                         style = "font-size:10px; width:20px; margin-right:2px; color:black;"),
                             tabName = "calidad")
        ),
        
        menuItem("Estado de Resultados", tabName = "resultados", 
                 icon = icon("chart-bar",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;")
                 ),
        
        menuItem("Indicadores Financieros", tabName = "indicadores", 
                 icon = icon("chart-line",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;")
                 ),
        
        menuItem("Interpretación", tabName = "interpretacion", 
                 icon = icon("lightbulb",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;")
                ),
        
        # menuItem("Análisis Geográfico", tabName = "analisis_geografico", 
        #          icon = icon("map",
        #                      class = "fa-fw",
        #                      style = "font-size:20px; width:36px; margin-right:8px; color:black;")
        #          )
        
        menuItem("Análisis Geográfico", tabName = "geo_dummy",
                 icon = icon("map",
                             class = "fa-fw",
                             style = "font-size:20px; width:36px; margin-right:8px; color:black;"),
                 
                 menuSubItem("Mapa de Colocaciones",
                             icon = icon("map-marker-alt",
                                         class = "fa-fw",
                                         style = "font-size:10px; width:20px; margin-right:2px; color:black;"),
                             tabName = "mapa_colocaciones"),
                 
                 menuSubItem("Comparativa de Bancos",
                             icon = icon("chart-bar",
                                         class = "fa-fw",
                                         style = "font-size:10px; width:20px; margin-right:2px; color:black;"),
                             tabName = "comparativa_bancos")
        )
      )
    ),

  dashboardBody(
    useShinyjs(),
    
    tags$head(tags$style(HTML("
    
          /*#### estilo de titulo de box ####*/
      .box-title-custom {
      font-size: 14px; text-align: center
      }
      
      /*#### estilo de btn-custom ####*/
      .btn-custom {
      width: 100%; /* Ancho del botón */
      background-color: #D8DEE9; /* Color de fondo */
      color: #000000; /* Color del texto */
      border: none; /* Sin borde */
      border-radius: 5px; /* Bordes redondeados */
      padding: 10px; /* Espaciado interno */
      font-size: 14px; /* Tamaño de la fuente */
      cursor: pointer; /* Cambia el cursor al pasar sobre el botón */
      transition: background-color 0.3s; /* Transición suave para el color de fondo */
      }

      /*#### Color de fondo al pasar el cursor ####*/
      .btn-custom:hover {
      background-color: #005bb5;
      color: white
      }

      /*#### color de espacio para de titulo ####*/
      .skin-blue .main-header .logo {
        background-color: #0066cc;
      }

      /*#### color del resto de la barra de titulo ####*/
      .skin-blue .main-header .navbar {
        background-color: #0066cc;
      }

      /*#### color del dashboardSidebar ####*/
      .skin-blue .main-sidebar {
        background-color: #D8DEE9;
      }

      /*#### color del texto de items y en dashboardSidebar ####*/
      .skin-blue .main-sidebar .sidebar .sidebar-menu a {
        background-color: #D8DEE9; /* fondo cuadro */
        color: black; /* texto */
      }

      /*#### color de sidebarmenu con click ####*/
      .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
        background-color: whitesmoke;
      }
      
      /*#### Scroll en dashboardBody ####*/
      .content-wrapper { 
      overflow-y: auto; 
      max-height: 100vh; 
      padding-bottom: 60px;
      }
      
      .btn-xs {
      padding: 3px 6px;
      font-size: 12px;
      }

      /*#### color del dashboardBody ####*/
      .content-wrapper, .right-side {
        background-color: whitesmoke;
      }

      # 
      # 
      # .skin-blue .main-header .logo, .skin-blue .main-header .navbar { background-color:#003087; }
      # .skin-blue .main-sidebar { background-color:#1a252f; }
      # .skin-blue .main-sidebar .sidebar .sidebar-menu a { background-color:#1a252f; color:#ecf0f1; }
      # .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover { background-color:#2c3e50; }
      # .skin-blue .sidebar-menu > li.active > a { border-left-color:#E8891D; color:#fff; }
      # .content-wrapper, .right-side { background-color:#F0F2F5; }
      
      /* Scroll suave */
      .content-wrapper { overflow-y:auto; max-height:100vh; padding-bottom:60px; }
      
      /* Grid responsivo */
      .grid-2cols { display:grid; grid-template-columns:repeat(2,1fr); gap:20px; margin-bottom:20px; }
      .grid-3cols { display:grid; grid-template-columns:repeat(3,1fr); gap:20px; margin-bottom:20px; }
      @media (max-width:1000px) { .grid-2cols, .grid-3cols { grid-template-columns:1fr; } }
      
      .kpi-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:15px; margin-bottom:25px; }
      @media (max-width:800px) { .kpi-grid { grid-template-columns:repeat(2,1fr); } }
      
      .sec-title {
        color:#003087; font-size:22px; font-weight:700;
        border-left:5px solid #003087; padding-left:15px;
        margin:0 0 20px; letter-spacing:-0.3px;
      }
      .subsec { color:#5D6D7E; font-size:13px; margin-bottom:20px; margin-top:-10px; }
      
      /* Portada */
      body,html{ font-family:'Segoe UI',Arial,sans-serif; margin:0; padding:0; }
      #financeChart{ position:absolute; top:0; left:0; width:100%; height:100vh; z-index:0; }
      .contenido{
        position:relative; z-index:1; height:100vh;
        display:flex; flex-direction:column;
        justify-content:center; align-items:center; text-align:center;
        background:rgba(10,15,20,.55); padding:0 20px;
      }
      .contenido h1{ font-size:2.6em; margin:0 0 8px; color:#00ffaa; text-shadow:0 0 12px #00ffaa; }
      .contenido h2{ font-size:1.3em; margin:0 0 28px; color:#ffaa00; }
      .boton-ingreso{
        font-size:1.1em; padding:12px 32px; background:#ffaa00; border:none;
        border-radius:30px; color:#000; cursor:pointer;
        box-shadow:0 0 18px #ffaa00; transition:all .3s;
      }
      .boton-ingreso:hover{ background:#ffcc33; transform:scale(1.05); }
    "))),
    
    tabItems(
      
      # INICIO
      tabItem("inicio",
              tags$canvas(id = "financeChart"),
              tags$div(class = "contenido",
                       tags$h1("Aplicativo de Análisis Financiero"),
                       tags$h2("Gerencia de Diseño Estratégico"),
                       actionButton("goApp", "Ingresar al Sistema", class = "boton-ingreso")
              ),
              tags$script(HTML("
          const canvas=document.getElementById('financeChart'),ctx=canvas.getContext('2d');
          let W,H;
          function resize(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight;}
          window.addEventListener('resize',resize);resize();
          const N=60;
          let l1=Array.from({length:N},()=>H/2),l2=Array.from({length:N},()=>H/2);
          let a1=Array.from({length:N},()=>H/2),a2=[...a1],a3=[...a1];
          let fc=0;
          function upd(){
            if(fc%18===0){
              l1.shift();l2.shift();
              let n1=l1[N-2]+(Math.random()-.5)*80,n2=l2[N-2]+(Math.random()-.5)*80;
              n1=Math.max(H*.1,Math.min(H*.9,n1));n2=Math.max(H*.1,Math.min(H*.9,n2));
              l1.push(n1);l2.push(n2);
              const t=Date.now()*.0005;
              for(let i=0;i<N;i++){
                a1[i]=H/2+Math.sin(t+i*.15)*H/6;
                a2[i]=H/2+Math.cos(t+i*.12)*H/7;
                a3[i]=H/2+Math.sin(t+i*.10)*H/9;
              }
            }fc++;
          }
          function grid(){
            ctx.strokeStyle='rgba(0,255,255,0.05)';
            for(let x=0;x<W;x+=80){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,H);ctx.stroke();}
            for(let y=0;y<H;y+=80){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(W,y);ctx.stroke();}
          }
          function area(d,col){
            ctx.beginPath();ctx.moveTo(0,H);
            for(let i=0;i<N;i++)ctx.lineTo(i*(W/(N-1)),d[i]);
            ctx.lineTo(W,H);ctx.closePath();ctx.fillStyle=col;ctx.fill();
          }
          function line(d,col){
            ctx.beginPath();ctx.moveTo(0,d[0]);
            for(let i=1;i<N;i++)ctx.lineTo(i*(W/(N-1)),d[i]);
            ctx.strokeStyle=col;ctx.lineWidth=2;ctx.shadowBlur=8;ctx.shadowColor=col;
            ctx.stroke();ctx.shadowBlur=0;
          }
          function animate(){
            ctx.fillStyle='rgba(10,15,20,0.28)';ctx.fillRect(0,0,W,H);
            grid();upd();
            area(a3,'rgba(0,255,255,0.05)');area(a2,'rgba(0,255,255,0.07)');area(a1,'rgba(0,255,255,0.10)');
            line(l1,'#00ffaa');line(l2,'#ffaa00');
            requestAnimationFrame(animate);
          }
          animate();
        "))
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # ESTRUCTURA FINANCIERA
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("estructura",
              div(class = "sec-title", "Balance General › Estructura Financiera"),
              div(class = "subsec", "Activo, Pasivo y Patrimonio del Banco del Pacífico y del Sistema Financiero Nacional"),
              
              div(class = "kpi-grid",
                  kpi_card("Activo BP 2025", tail(bp$activo,1), tail(var_rel(bp$activo),1)),
                  kpi_card("Pasivo BP 2025", tail(bp$pasivo,1), tail(var_rel(bp$pasivo),1)),
                  kpi_card("Patrimonio BP 2025", tail(bp$patrimonio,1), tail(var_rel(bp$patrimonio),1)),
                  kpi_card("Part. Activo en Sis.", pct(tail(bp$activo,1), tail(sis$activo,1)), is_pct = TRUE)
              ),
              
              div(class = "grid-2cols",
                  custom_card("Activo, Pasivo y Patrimonio – BP", icon_name = "chart-simple",
                              highchartOutput("ef_saldos_bp", height = "320px")),
                  custom_card("Activo, Pasivo y Patrimonio – Sistema", icon_name = "building",
                              highchartOutput("ef_saldos_sis", height = "320px"))
              ),
              
              custom_card("Participación del BP en el Sistema Financiero (%)", icon_name = "percent",
                          highchartOutput("ef_participacion", height = "320px")),
              
              div(class = "grid-2cols",
                  custom_card("Variación Absoluta Anual – BP (MM USD)", icon_name = "arrow-up",
                              highchartOutput("ef_var_abs", height = "320px")),
                  custom_card("Variación Relativa Anual – BP (%)", icon_name = "percentage",
                              highchartOutput("ef_var_rel", height = "320px"))
              )
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # INTERMEDIACIÓN FINANCIERA
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("intermediacion",
              div(class = "sec-title", "Balance General › Intermediación Financiera"),
              div(class = "subsec", "Cartera Bruta, Obligaciones con el Público, Obligaciones Financieras e Indicador de Intermediación"),
              
              div(class = "kpi-grid",
                  kpi_card("Cartera Bruta BP 2025", tail(bp$cartera_bruta,1), tail(var_rel(bp$cartera_bruta),1)),
                  kpi_card("Oblig. Público BP 2025", tail(bp$oblig_publico,1), tail(var_rel(bp$oblig_publico),1)),
                  kpi_card("Ind. Intermediación BP", tail(bp$intermediacion,1), is_pct = TRUE),
                  kpi_card("Part. Cartera en Sis.", pct(tail(bp$cartera_bruta,1), tail(sis$cartera_bruta,1)), is_pct = TRUE)
              ),
              
              div(class = "grid-2cols",
                  custom_card("Cartera Bruta – BP vs Sistema", icon_name = "chart-line",
                              highchartOutput("int_cartera", height = "300px")),
                  custom_card("Obligaciones con el Público", icon_name = "users",
                              highchartOutput("int_oblig_pub", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Obligaciones Financieras", icon_name = "money-bill",
                              highchartOutput("int_oblig_fin", height = "300px")),
                  custom_card("Indicador de Intermediación (%)", icon_name = "calculator",
                              highchartOutput("int_indicador", height = "300px"))
              ),
              
              custom_card("Participación BP en el Sistema – 4 Variables (%)", icon_name = "chart-pie",
                          highchartOutput("int_participacion", height = "320px")),
              
              div(class = "grid-2cols",
                  custom_card("Variación Absoluta Anual – BP (MM USD)", icon_name = "arrow-trend-up",
                              highchartOutput("int_var_abs", height = "310px")),
                  custom_card("Variación Relativa Anual – BP (%)", icon_name = "percent",
                              highchartOutput("int_var_rel", height = "310px"))
              )
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # CALIDAD DE CARTERA
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("calidad",
              div(class = "sec-title", "Balance General › Calidad de Cartera"),
              div(class = "subsec", "Cartera por Vencer y Cartera Improductiva (QNDI + Vencida)"),
              
              div(class = "kpi-grid",
                  kpi_card("Cartera por Vencer BP 2025", tail(bp$cartera_pv,1), tail(var_rel(bp$cartera_pv),1)),
                  kpi_card("Cartera Improductiva BP 2025", tail(bp$cartera_imp,1), tail(var_rel(bp$cartera_imp),1)),
                  kpi_card("Morosidad BP 2025", pct(tail(bp$cartera_imp,1), tail(bp$cartera_bruta,1)), is_pct = TRUE),
                  kpi_card("Morosidad Sistema 2025", pct(tail(sis$cartera_imp,1), tail(sis$cartera_bruta,1)), is_pct = TRUE)
              ),
              
              div(class = "grid-2cols",
                  custom_card("Cartera por Vencer – BP vs Sistema", icon_name = "calendar-check",
                              highchartOutput("cal_pv", height = "300px")),
                  custom_card("Cartera Improductiva – BP vs Sistema", icon_name = "exclamation-triangle",
                              highchartOutput("cal_imp", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Composición Cartera BP – Área Apilada", icon_name = "chart-gantt",
                              highchartOutput("cal_comp_bp", height = "320px")),
                  custom_card("Composición Cartera Sistema – Área Apilada", icon_name = "chart-gantt",
                              highchartOutput("cal_comp_sis", height = "320px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Composición % – BP", icon_name = "pie-chart",
                              highchartOutput("cal_comp_bp_pct", height = "300px")),
                  custom_card("Composición % – Sistema", icon_name = "pie-chart",
                              highchartOutput("cal_comp_sis_pct", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Participación BP en el Sistema – 2 Variables (%)", icon_name = "percent",
                              highchartOutput("cal_participacion", height = "300px")),
                  custom_card("Índice de Morosidad – BP vs Sistema (%)", icon_name = "triangle-exclamation",
                              highchartOutput("cal_morosidad", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Variación Absoluta Anual – BP (MM USD)", icon_name = "arrow-trend-up",
                              highchartOutput("cal_var_abs", height = "300px")),
                  custom_card("Variación Relativa Anual – BP (%)", icon_name = "percent",
                              highchartOutput("cal_var_rel", height = "300px"))
              )
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # ESTADO DE RESULTADOS
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("resultados",
              div(class = "sec-title", "Estado de Resultados"),
              div(class = "subsec", "Ingresos totales, Gastos totales y Utilidad Neta del BP y del Sistema Financiero"),
              
              div(class = "kpi-grid",
                  kpi_card("Ingresos BP 2025", tail(bp$ingresos,1), tail(var_rel(bp$ingresos),1)),
                  kpi_card("Gastos BP 2025", tail(bp$gastos,1), tail(var_rel(bp$gastos),1)),
                  kpi_card("Utilidad Neta BP 2025", tail(bp$utilidad,1), tail(var_rel(bp$utilidad),1)),
                  kpi_card("Part. Utilidad en Sis.", pct(tail(bp$utilidad,1), tail(sis$utilidad,1)), is_pct = TRUE)
              ),
              
              div(class = "grid-2cols",
                  custom_card("Ingresos, Gastos y Utilidad Neta – BP", icon_name = "chart-line",
                              highchartOutput("er_saldos_bp", height = "320px")),
                  custom_card("Ingresos, Gastos y Utilidad Neta – Sistema", icon_name = "building",
                              highchartOutput("er_saldos_sis", height = "320px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Composición de Ingresos – BP", icon_name = "chart-pie",
                              highchartOutput("er_comp_ing_bp", height = "320px")),
                  custom_card("Margen Bruto Financiero vs Gastos de Operación", icon_name = "scale-balanced",
                              highchartOutput("er_mbf", height = "320px"))
              ),
              
              custom_card("Participación BP en el Sistema – 3 Variables (%)", icon_name = "percent",
                          highchartOutput("er_participacion", height = "320px")),
              
              div(class = "grid-2cols",
                  custom_card("Variación Absoluta Anual – BP (MM USD)", icon_name = "arrow-up",
                              highchartOutput("er_var_abs", height = "310px")),
                  custom_card("Variación Relativa Anual – BP (%)", icon_name = "percentage",
                              highchartOutput("er_var_rel", height = "310px"))
              )
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # INDICADORES FINANCIEROS
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("indicadores",
              div(class = "sec-title", "Indicadores Financieros"),
              div(class = "subsec", "ROE, ROA, Eficiencia, Liquidez, Morosidad y Cobertura – BP vs Sistema"),
              
              div(class = "kpi-grid",
                  kpi_card("ROE BP", tail(bp$roe,1), is_pct = TRUE),
                  kpi_card("ROA BP", tail(bp$roa,1), is_pct = TRUE),
                  kpi_card("Eficiencia BP", tail(bp$eficiencia,1), is_pct = TRUE),
                  kpi_card("Liquidez BP", tail(bp$liquidez,1), is_pct = TRUE)
              ),
              
              div(class = "grid-2cols",
                  custom_card("ROE = Utilidad Neta / Patrimonio (%)", icon_name = "chart-line",
                              highchartOutput("ind_roe", height = "300px")),
                  custom_card("ROA = Utilidad Neta / Activo (%)", icon_name = "chart-line",
                              highchartOutput("ind_roa", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Eficiencia = Gastos Operación / Margen Bruto Financiero (%)", 
                              subtitle = "Menor valor = Mayor eficiencia", icon_name = "gauge-high",
                              highchartOutput("ind_eficiencia", height = "300px")),
                  custom_card("Liquidez = Fondos Disponibles / (Dep. Vista + Dep. Plazo) (%)", icon_name = "droplet",
                              highchartOutput("ind_liquidez", height = "300px"))
              ),
              
              div(class = "grid-2cols",
                  custom_card("Morosidad = Cartera Improductiva / Cartera Bruta (%)", icon_name = "triangle-exclamation",
                              highchartOutput("ind_morosidad", height = "300px")),
                  custom_card("Cobertura = Provisiones (1499) / Cartera Improductiva (%)",
                              subtitle = "Mayor valor = Mejor cobertura del riesgo", icon_name = "shield-haltered",
                              highchartOutput("ind_cobertura", height = "300px"))
              ),
              
              custom_card("Radar de Indicadores – BP vs Sistema (Dic 2025)", icon_name = "chart-scatter",
                          highchartOutput("ind_radar", height = "450px"))
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # INTERPRETACIÓN
      # ═══════════════════════════════════════════════════════════════════════
      # tabItem("interpretacion",
      #         div(class = "sec-title", "Interpretación de Resultados"),
      #         div(class = "subsec", "Análisis cualitativo de los principales hallazgos"),
      #         
      #         custom_card("Resumen Ejecutivo 2025", icon_name = "file-lines",
      #                     div(style = "line-height:1.6;color:#2C3E50;",
      #                         tags$p(tags$strong("Banco del Pacífico:"), 
      #                                "El Banco muestra un crecimiento sostenido en activos (+13.6% vs 2024), 
      #               impulsado por una expansión de la cartera de créditos (+19.3%). 
      #               La utilidad neta alcanza los $206 MM, con un ROE del 18.5% muy superior al 
      #               promedio del sistema (12.0%)."),
      #                         tags$p(tags$strong("Eficiencia:"), 
      #                                "El indicador de eficiencia mejoró significativamente pasando de 65% en 2021 
      #               a 42.4% en 2025, ubicándose por debajo del promedio del sistema (49.8%)."),
      #                         tags$p(tags$strong("Calidad de Cartera:"), 
      #                                "La morosidad se redujo a 2.54% en 2025 (vs 3.82% en 2023), mejor que el sistema 
      #               que registró 2.93%. La cobertura con provisiones alcanza 244%, muy por encima 
      #               del mínimo regulatorio del 100%."),
      #                         tags$p(tags$strong("Liquidez:"), 
      #                                "El indicador de liquidez (22.9%) se mantiene en niveles saludables, aunque 
      #               ligeramente por debajo del promedio histórico del Banco."),
      #                         tags$p(tags$strong("Perspectivas:"), 
      #                                "Se recomienda mantener el enfoque en la expansión de la cartera de créditos 
      #               comercial y consumo, monitoreando de cerca la evolución de la cartera improductiva 
      #               y fortaleciendo las estrategias de captación de depósitos del público.")
      #                     )
      #         ),
      #         
      #         div(class = "grid-2cols",
      #             custom_card("Fortalezas", icon_name = "thumbs-up",
      #                         tags$ul(style = "margin:0;padding-left:20px;",
      #                                 tags$li("ROE consistentemente superior al sistema (18.5% vs 12.0%)"),
      #                                 tags$li("Eficiencia operativa en mejora continua (42.4%)"),
      #                                 tags$li("Excelente cobertura de provisiones (244%)"),
      #                                 tags$li("Crecimiento sostenido de utilidades (+260% desde 2021)")
      #                         )
      #             ),
      #             custom_card("Áreas de Oportunidad", icon_name = "lightbulb",
      #                         tags$ul(style = "margin:0;padding-left:20px;",
      #                                 tags$li("Mejorar el indicador de liquidez frente al sistema"),
      #                                 tags$li("Reducir la dependencia de obligaciones financieras"),
      #                                 tags$li("Fortalecer la participación en cartera de consumo"),
      #                                 tags$li("Optimizar la estructura de financiamiento")
      #                         )
      #             )
      #         )
      # ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # INTERPRETACIÓN DE RESULTADOS - CON TABPANEL
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("interpretacion",
              div(class = "sec-title", "Interpretación de Resultados"),
              div(class = "subsec", "Análisis profesional basado en la evidencia de los datos 2021-2025"),
              
              tabsetPanel(
                type = "tabs",
                
                # ==================== TAB 1: BALANCE GENERAL ====================
                tabPanel("Balance General",
                         br(),
                         
                         # Estructura Financiera
                         custom_card("Análisis de la Estructura Financiera", icon_name = "balance-scale",
                                     uiOutput("analisis_estructura_financiera")
                         ),
                         
                         # Intermediación Financiera
                         custom_card("Análisis de la Intermediación Financiera", icon_name = "exchange-alt",
                                     uiOutput("analisis_intermediacion_financiera")
                         ),
                         
                         # Calidad de Cartera
                         custom_card("Análisis de la Calidad de Cartera", icon_name = "chart-line",
                                     uiOutput("analisis_calidad_cartera")
                         )
                ),
                
                # ==================== TAB 2: ESTADO DE RESULTADOS ====================
                tabPanel("Estado de Resultados",
                         br(),
                         
                         custom_card("Análisis de Ingresos, Gastos y Utilidad", icon_name = "chart-bar",
                                     uiOutput("analisis_resultados_er")
                         ),
                         
                         custom_card("Análisis del Margen Bruto Financiero y Eficiencia Operativa", icon_name = "calculator",
                                     uiOutput("analisis_mbf_eficiencia")
                         )
                         
                         # custom_card("Análisis de Provisiones e Impuestos", icon_name = "shield-alt",
                         #             uiOutput("analisis_provisiones_impuestos")
                         # )
                ),
                
                # ==================== TAB 3: INDICADORES FINANCIEROS ====================
                tabPanel("Indicadores Financieros",
                         br(),
                         
                         custom_card("Análisis de Rentabilidad (ROE y ROA)", icon_name = "chart-line",
                                     uiOutput("analisis_rentabilidad_indicadores")
                         ),
                         
                         custom_card("Análisis de Eficiencia y Liquidez", icon_name = "tachometer-alt",
                                     uiOutput("analisis_eficiencia_liquidez")
                         ),
                         
                         custom_card("Análisis de Riesgo Crediticio (Morosidad y Cobertura)", icon_name = "exclamation-triangle",
                                     uiOutput("analisis_riesgo_crediticio")
                         ),
                         
                         custom_card("Análisis Comparativo BP vs Sistema Financiero", icon_name = "building",
                                     uiOutput("analisis_comparativo_sistema")
                         )
                )
              )
      ),
      
      
      # ═══════════════════════════════════════════════════════════════════════
      # ANÁLISIS GEOGRÁFICO DE COLOCACIONES
      # ═══════════════════════════════════════════════════════════════════════
      # tabItem("analisis_geografico",
      #         div(class = "sec-title", "Análisis Geográfico de Colocaciones"),
      #         div(class = "subsec", "Distribución de colocaciones por provincia y banco (Millones USD)"),
      #         
      #         # Filtros
      #         custom_card("Filtros", icon_name = "sliders-h",
      #                     fluidRow(
      #                       column(6,
      #                              selectInput("banco_geo", "Seleccionar Banco:",
      #                                          choices = c("TODOS LOS BANCOS", bancos_disponibles),
      #                                          selected = "BP PACIFICO",
      #                                          width = "100%")
      #                       ),
      #                       column(4,
      #                              selectInput("provincia_geo", "Filtrar por Provincia (Opcional):",
      #                                          choices = c("Todas", provincias_disponibles),
      #                                          selected = "Todas",
      #                                          width = "100%")
      #                       ),
      #                       column(2,
      #                              actionButton("reset_geo", "Resetear", 
      #                                           icon = icon("refresh"), 
      #                                           class = "btn-custom",
      #                                           style = "margin-top: 25px; width: 100%;")
      #                       )
      #                     )
      #         ),
      #         
      #         # Mapa e información
      #         div(class = "grid-2cols",
      #             custom_card("Mapa de Colocaciones por Provincia", icon_name = "map",
      #                         highchartOutput("mapa_geo", height = "450px")),
      #             custom_card("Información del Banco", icon_name = "university",
      #                         uiOutput("info_banco_geo"),
      #                         br(),
      #                         h4("Top 5 Provincias"),
      #                         tableOutput("top_provincias_geo"))
      #         ),
      #         
      #         # Tabla detallada
      #         custom_card("Detalle de Colocaciones por Provincia", icon_name = "table",
      #                     DTOutput("tabla_colocaciones_geo"))
      # )
      
      
      # ═══════════════════════════════════════════════════════════════════════
      # ANÁLISIS GEOGRÁFICO - MAPA DE COLOCACIONES
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("mapa_colocaciones",
              div(class = "sec-title", "Análisis Geográfico › Mapa de Colocaciones"),
              div(class = "subsec", "Distribución geográfica de colocaciones por provincia (Millones USD). Pase el mouse sobre cada provincia para ver el valor exacto."),
              
              # Filtros
              custom_card("Filtros", icon_name = "sliders-h",
                          fluidRow(
                            column(6,
                                   selectInput("banco_geo", "Seleccionar Banco:",
                                               choices = c("TODOS LOS BANCOS", bancos_disponibles),
                                               selected = "BP PACIFICO",
                                               width = "100%")
                            ),
                            column(4,
                                   selectInput("provincia_geo", "Filtrar por Provincia (Opcional):",
                                               choices = c("Todas", provincias_disponibles),
                                               selected = "Todas",
                                               width = "100%")
                            ),
                            column(2,
                                   actionButton("reset_geo", "Resetear", 
                                                icon = icon("refresh"), 
                                                class = "btn-custom",
                                                style = "margin-top: 25px; width: 100%;")
                            )
                          )
              ),
              
              # Mapa e información
              div(class = "grid-2cols",
                  custom_card("Mapa de Colocaciones por Provincia", icon_name = "map",
                              tags$div(style = "font-size:12px; color:#666; margin-bottom:10px;",
                                       "💡 Tip: Pase el mouse sobre cualquier provincia para ver el monto exacto de colocaciones"),
                              highchartOutput("mapa_geo", height = "480px")),
                  custom_card("Información del Banco", icon_name = "university",
                              uiOutput("info_banco_geo"),
                              br(),
                              h4("📊 Top 5 Provincias"),
                              tableOutput("top_provincias_geo"))
              ),
              
              # Tabla detallada
              custom_card("Detalle Completo de Colocaciones por Provincia", icon_name = "table",
                          DTOutput("tabla_colocaciones_geo"))
      ),
      
      # ═══════════════════════════════════════════════════════════════════════
      # ANÁLISIS GEOGRÁFICO - COMPARATIVA DE BANCOS
      # ═══════════════════════════════════════════════════════════════════════
      tabItem("comparativa_bancos",
              div(class = "sec-title", "Análisis Geográfico › Comparativa de Bancos"),
              div(class = "subsec", "Ranking y comparativa de colocaciones por entidad financiera (Millones USD)"),
              
              div(class = "grid-2cols",
                  custom_card("Top 10 Bancos por Colocación", icon_name = "trophy",
                              highchartOutput("barras_top10", height = "400px")),
                  custom_card("Participación por Banco (%)", icon_name = "chart-pie",
                              highchartOutput("pie_participacion", height = "400px"))
              ),
              
              custom_card("Ranking Completo de Bancos", icon_name = "list-ol",
                          DTOutput("tabla_bancos_geo")),
              
              div(class = "grid-2cols",
                  custom_card("Concentración de Mercado", icon_name = "chart-line",
                              uiOutput("concentracion_texto")),
                  custom_card("Mapa de Calor - Bancos vs Provincias", icon_name = "border-all",
                              highchartOutput("heatmap_bancos", height = "400px"))
              )
      )
      
      
    )
  )
)

# ══════════════════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════════════════
server <- function(input, output, session) {
  
  observeEvent(input$goApp, { updateTabItems(session, "tabs", "estructura") })
  
  observeEvent(input$autor_btn, {
    showModal(modalDialog(
      title = tags$strong("Información del Autor"),
      tags$p("Gerencia de Diseño Estratégico"),
      tags$p("Banco del Pacífico – 2025"),
      easyClose = TRUE, footer = modalButton("Cerrar")
    ))
  })
  
  # ============================================================================
  # ESTRUCTURA FINANCIERA
  # ============================================================================
  output$ef_saldos_bp <- renderHighchart({
    hc_base("") %>%
      hc_column(bp$activo, "Activo", C$bp1) %>%
      hc_column(bp$pasivo, "Pasivo", C$bp2) %>%
      hc_column(bp$patrimonio, "Patrimonio", C$bp3) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1, borderWidth = 0))
  })
  
  output$ef_saldos_sis <- renderHighchart({
    hc_base("") %>%
      hc_column(sis$activo, "Activo", C$s1) %>%
      hc_column(sis$pasivo, "Pasivo", "#D4761A") %>%
      hc_column(sis$patrimonio, "Patrimonio", C$s2) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1, borderWidth = 0))
  })
  
  output$ef_participacion <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(pct(bp$activo, sis$activo), "Part. Activo", C$bp1) %>%
      hc_line(pct(bp$pasivo, sis$pasivo), "Part. Pasivo", C$bp2) %>%
      hc_line(pct(bp$patrimonio, sis$patrimonio), "Part. Patrimonio", C$bp3)
  })
  
  output$ef_var_abs <- renderHighchart({
    hc_base("") %>%
      hc_column(var_abs(bp$activo), "Δ Activo", C$bp1) %>%
      hc_column(var_abs(bp$pasivo), "Δ Pasivo", C$bp2) %>%
      hc_column(var_abs(bp$patrimonio), "Δ Patrimonio", C$bp3) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$ef_var_rel <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(var_rel(bp$activo), "Δ% Activo", C$bp1) %>%
      hc_line(var_rel(bp$pasivo), "Δ% Pasivo", C$bp2) %>%
      hc_line(var_rel(bp$patrimonio), "Δ% Patrimonio", C$bp3)
  })
  
  # ============================================================================
  # INTERMEDIACIÓN
  # ============================================================================
  output$int_cartera <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$cartera_bruta, "Cartera BP", C$bp1) %>%
      hc_line(sis$cartera_bruta / 8, "Cartera Sis ÷8", C$s1, "dash")
  })
  
  output$int_oblig_pub <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$oblig_publico, "Oblig. Público BP", C$bp1) %>%
      hc_line(sis$oblig_publico / 8, "Oblig. Sis ÷8", C$s1, "dash")
  })
  
  output$int_oblig_fin <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$oblig_financieras, "Oblig. Fin. BP", C$bp1) %>%
      hc_line(sis$oblig_financieras / 6, "Oblig. Fin. Sis ÷6", C$s1, "dash")
  })
  
  output$int_indicador <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$intermediacion, "Ind. Interm. BP", C$bp1) %>%
      hc_line(sis$intermediacion, "Ind. Interm. Sistema", C$s1, "dash")
  })
  
  output$int_participacion <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(pct(bp$cartera_bruta, sis$cartera_bruta), "Part. Cartera Bruta", C$bp1) %>%
      hc_line(pct(bp$oblig_publico, sis$oblig_publico), "Part. Oblig. Público", C$bp2) %>%
      hc_line(pct(bp$oblig_financieras, sis$oblig_financieras), "Part. Oblig. Fin.", C$bp3) %>%
      hc_line(pct(bp$intermediacion, sis$intermediacion), "Rel. Índice Interm.", C$s1, "dash")
  })
  
  output$int_var_abs <- renderHighchart({
    hc_base("") %>%
      hc_column(var_abs(bp$cartera_bruta), "Δ Cartera Bruta", C$bp1) %>%
      hc_column(var_abs(bp$oblig_publico), "Δ Oblig. Público", C$bp2) %>%
      hc_column(var_abs(bp$oblig_financieras), "Δ Oblig. Fin.", C$bp3) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$int_var_rel <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(var_rel(bp$cartera_bruta), "Δ% Cartera Bruta", C$bp1) %>%
      hc_line(var_rel(bp$oblig_publico), "Δ% Oblig. Público", C$bp2) %>%
      hc_line(var_rel(bp$oblig_financieras), "Δ% Oblig. Fin.", C$bp3)
  })
  
  # ============================================================================
  # CALIDAD DE CARTERA
  # ============================================================================
  output$cal_pv <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$cartera_pv, "Por Vencer BP", C$bp1) %>%
      hc_line(sis$cartera_pv / 8, "Por Vencer Sis ÷8", C$s1, "dash")
  })
  
  output$cal_imp <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$cartera_imp, "Improductiva BP", C$red) %>%
      hc_line(sis$cartera_imp / 8, "Improductiva Sis ÷8", C$s1, "dash")
  })
  
  output$cal_comp_bp <- renderHighchart({
    hc_base("") %>%
      hc_area(bp$cartera_vencida, "Vencida", C$red) %>%
      hc_area(bp$cartera_qndi, "QNDI", C$s1) %>%
      hc_area(bp$cartera_pv, "Por Vencer", C$bp2)
  })
  
  output$cal_comp_sis <- renderHighchart({
    hc_base("") %>%
      hc_area(sis$cartera_vencida, "Vencida", C$red) %>%
      hc_area(sis$cartera_qndi, "QNDI", "#8E44AD") %>%
      hc_area(sis$cartera_pv, "Por Vencer", C$s1)
  })
  
  output$cal_comp_bp_pct <- renderHighchart({
    tot <- bp$cartera_pv + bp$cartera_qndi + bp$cartera_vencida
    highchart() %>%
      hc_chart(type = "column", backgroundColor = "white") %>%
      hc_xAxis(categories = as.character(years)) %>%
      hc_yAxis(title = list(text = "%"), labels = list(format = "{value}%")) %>%
      hc_add_series(name = "Por Vencer", data = round(bp$cartera_pv/tot*100, 2), color = C$bp2) %>%
      hc_add_series(name = "QNDI", data = round(bp$cartera_qndi/tot*100, 2), color = C$s1) %>%
      hc_add_series(name = "Vencida", data = round(bp$cartera_vencida/tot*100, 2), color = C$red) %>%
      hc_plotOptions(column = list(stacking = "normal", dataLabels = list(enabled = TRUE, format = "{y:.1f}%"))) %>%
      hc_tooltip(shared = TRUE, valueSuffix = "%")
  })
  
  output$cal_comp_sis_pct <- renderHighchart({
    tot <- sis$cartera_pv + sis$cartera_qndi + sis$cartera_vencida
    highchart() %>%
      hc_chart(type = "column", backgroundColor = "white") %>%
      hc_xAxis(categories = as.character(years)) %>%
      hc_yAxis(title = list(text = "%"), labels = list(format = "{value}%")) %>%
      hc_add_series(name = "Por Vencer", data = round(sis$cartera_pv/tot*100, 2), color = C$s1) %>%
      hc_add_series(name = "QNDI", data = round(sis$cartera_qndi/tot*100, 2), color = "#8E44AD") %>%
      hc_add_series(name = "Vencida", data = round(sis$cartera_vencida/tot*100, 2), color = C$red) %>%
      hc_plotOptions(column = list(stacking = "normal", dataLabels = list(enabled = TRUE, format = "{y:.1f}%"))) %>%
      hc_tooltip(shared = TRUE, valueSuffix = "%")
  })
  
  output$cal_participacion <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(pct(bp$cartera_pv, sis$cartera_pv), "Part. Por Vencer", C$bp1) %>%
      hc_line(pct(bp$cartera_imp, sis$cartera_imp), "Part. Improductiva", C$red)
  })
  
  output$cal_morosidad <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(pct(bp$cartera_imp, bp$cartera_bruta), "Morosidad BP", C$bp1) %>%
      hc_line(pct(sis$cartera_imp, sis$cartera_bruta), "Morosidad Sistema", C$s1, "dash")
  })
  
  output$cal_var_abs <- renderHighchart({
    hc_base("") %>%
      hc_column(var_abs(bp$cartera_pv), "Δ Por Vencer", C$bp1) %>%
      hc_column(var_abs(bp$cartera_imp), "Δ Improductiva", C$red) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$cal_var_rel <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(var_rel(bp$cartera_pv), "Δ% Por Vencer", C$bp1) %>%
      hc_line(var_rel(bp$cartera_imp), "Δ% Improductiva", C$red)
  })
  
  # ============================================================================
  # ESTADO DE RESULTADOS
  # ============================================================================
  output$er_saldos_bp <- renderHighchart({
    hc_base("") %>%
      hc_column(bp$ingresos, "Ingresos", C$grn) %>%
      hc_column(bp$gastos, "Gastos", C$red) %>%
      hc_line(bp$utilidad, "Utilidad Neta", C$bp1) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$er_saldos_sis <- renderHighchart({
    hc_base("") %>%
      hc_column(sis$ingresos, "Ingresos", C$grn) %>%
      hc_column(sis$gastos, "Gastos", C$red) %>%
      hc_line(sis$utilidad, "Utilidad Neta", C$s1) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$er_comp_ing_bp <- renderHighchart({
    hc_base("") %>%
      hc_area(bp$ingresos - bp$mbf, "Otros Ingresos", C$gry) %>%
      hc_area(bp$mbf, "Margen Bruto Financiero", C$bp2)
  })
  
  output$er_mbf <- renderHighchart({
    hc_base("") %>%
      hc_line(bp$mbf, "MBF BP", C$bp1) %>%
      hc_line(bp$gastos_op, "Gastos Op. BP", C$red) %>%
      hc_line(sis$mbf / 8, "MBF Sis ÷8", C$s1, "dash") %>%
      hc_line(sis$gastos_op / 8, "Gtos. Op. Sis ÷8", C$gry, "dash")
  })
  
  output$er_participacion <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(pct(bp$ingresos, sis$ingresos), "Part. Ingresos", C$grn) %>%
      hc_line(pct(bp$gastos, sis$gastos), "Part. Gastos", C$red) %>%
      hc_line(pct(bp$utilidad, sis$utilidad), "Part. Utilidad Neta", C$bp1)
  })
  
  output$er_var_abs <- renderHighchart({
    hc_base("") %>%
      hc_column(var_abs(bp$ingresos), "Δ Ingresos", C$grn) %>%
      hc_column(var_abs(bp$gastos), "Δ Gastos", C$red) %>%
      hc_column(var_abs(bp$utilidad), "Δ Utilidad Neta", C$bp1) %>%
      hc_plotOptions(column = list(grouping = FALSE, pointPadding = 0.1))
  })
  
  output$er_var_rel <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(var_rel(bp$ingresos), "Δ% Ingresos", C$grn) %>%
      hc_line(var_rel(bp$gastos), "Δ% Gastos", C$red) %>%
      hc_line(var_rel(bp$utilidad), "Δ% Utilidad Neta", C$bp1)
  })
  
  # ============================================================================
  # INDICADORES FINANCIEROS
  # ============================================================================
  output$ind_roe <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$roe, "ROE BP", C$bp1) %>%
      hc_line(sis$roe, "ROE Sistema", C$s1, "dash")
  })
  
  output$ind_roa <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$roa, "ROA BP", C$bp1) %>%
      hc_line(sis$roa, "ROA Sistema", C$s1, "dash")
  })
  
  output$ind_eficiencia <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$eficiencia, "Eficiencia BP", C$bp1) %>%
      hc_line(sis$eficiencia, "Eficiencia Sistema", C$s1, "dash") %>%
      hc_yAxis(plotLines = list(list(value = 50, color = C$red, width = 1.5, dashStyle = "Dash", label = list(text = "Umbral 50%"))))
  })
  
  output$ind_liquidez <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$liquidez, "Liquidez BP", C$bp1) %>%
      hc_line(sis$liquidez, "Liquidez Sistema", C$s1, "dash")
  })
  
  output$ind_morosidad <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$morosidad, "Morosidad BP", C$red) %>%
      hc_line(sis$morosidad, "Morosidad Sistema", C$s1, "dash")
  })
  
  output$ind_cobertura <- renderHighchart({
    hc_base("", y_title = "%", is_pct = TRUE) %>%
      hc_line(bp$cobertura, "Cobertura BP", C$grn) %>%
      hc_line(sis$cobertura, "Cobertura Sistema", C$s1, "dash") %>%
      hc_yAxis(plotLines = list(list(value = 100, color = C$red, width = 1.5, dashStyle = "Dash", label = list(text = "Mínimo 100%"))))
  })
  
  output$ind_radar <- renderHighchart({
    categories <- c("ROE", "ROA", "Eficiencia", "Liquidez", "Morosidad", "Cobertura")
    bp_vals <- c(tail(bp$roe,1), tail(bp$roa,1), tail(bp$eficiencia,1), 
                 tail(bp$liquidez,1), tail(bp$morosidad,1), tail(bp$cobertura,1))
    sis_vals <- c(tail(sis$roe,1), tail(sis$roa,1), tail(sis$eficiencia,1),
                  tail(sis$liquidez,1), tail(sis$morosidad,1), tail(sis$cobertura,1))
    
    highchart() %>%
      hc_chart(polar = TRUE, type = "line", backgroundColor = "white") %>%
      hc_xAxis(categories = categories, tickmarkPlacement = "on", lineWidth = 0) %>%
      hc_yAxis(gridLineInterpolation = "polygon", lineWidth = 0, min = 0) %>%
      hc_add_series(name = "BP 2025", data = bp_vals, color = C$bp1, lineWidth = 2.5,
                    marker = list(radius = 5), fillOpacity = 0.2) %>%
      hc_add_series(name = "Sistema 2025", data = sis_vals, color = C$s1, lineWidth = 2.5,
                    marker = list(radius = 5), fillOpacity = 0.2) %>%
      hc_tooltip(pointFormat = '<b>{series.name}</b><br>{point.key}: {point.y:.1f}%')
  })
  
  
  
  # ============================================================================
  # ANÁLISIS GEOGRÁFICO
  # ============================================================================
  
  # Datos filtrados para el mapa
  # datos_filtrados_geo <- reactive({
  #   req(exists("datos_colocaciones"))
  #   if(nrow(datos_colocaciones) == 0) return(data.frame())
  #   
  #   df <- datos_colocaciones
  #   
  #   if(input$banco_geo != "TODOS LOS BANCOS") {
  #     df <- df %>% filter(ENTIDAD == input$banco_geo)
  #   }
  #   
  #   if(input$provincia_geo != "Todas") {
  #     df <- df %>% filter(PROVINCIA == input$provincia_geo)
  #   }
  #   
  #   df %>%
  #     group_by(PROVINCIA, PROVINCIA_MAPA) %>%
  #     summarise(colocaciones = sum(MONTO_MM, na.rm = TRUE), .groups = 'drop')
  # })
  # 
  # # Mapa interactivo
  # output$mapa_geo <- renderHighchart({
  #   req(datos_filtrados_geo())
  #   df <- datos_filtrados_geo()
  #   if(nrow(df) == 0) return(highchart() %>% hc_title(text = "No hay datos"))
  #   
  #   valores <- df$colocaciones
  #   min_val <- ifelse(min(valores) > 0, min(valores) * 0.9, 0)
  #   max_val <- max(valores) * 1.1
  #   
  #   highchart(type = "map") %>%
  #     hc_add_series_map(
  #       map = download_map_data("countries/ec/ec-all"),
  #       df = df,
  #       value = "colocaciones",
  #       joinBy = c("name", "PROVINCIA_MAPA"),
  #       name = "Colocaciones (MM USD)",
  #       dataLabels = list(enabled = TRUE, format = "{point.name}", style = list(fontSize = "9px")),
  #       #tooltip = list(pointFormat = "<b>{point.name}</b><br> {point.colocaciones:.1f} MM USD"),
  #       
  #       tooltip = list(
  #         pointFormat = "<b>{point.name}</b><br> <b>{point.colocaciones:.1f} MM USD</b><br>📊 Participación: {point.percentage:.1f}%"
  #       ),
  #       
  #       borderColor = "#ffffff", borderWidth = 0.5
  #     ) %>%
  #     hc_colorAxis(min = min_val, max = max_val, type = "linear",
  #                  stops = color_stops(5, c("#2ecc71", "#f1c40f", "#e67e22", "#e74c3c", "#8e44ad"))) %>%
  #     hc_title(text = paste("Colocaciones -", input$banco_geo)) %>%
  #     hc_subtitle(text = "Millones de USD por provincia") %>%
  #     hc_legend(title = list(text = "MM USD"), align = "right", verticalAlign = "top", layout = "vertical") %>%
  #     hc_mapNavigation(enabled = TRUE) %>%
  #     hc_exporting(enabled = TRUE) %>%
  #     hc_chart(backgroundColor = "white")
  # })
  # 
  # # Información del banco
  # output$info_banco_geo <- renderUI({
  #   req(exists("datos_colocaciones"))
  #   if(nrow(datos_colocaciones) == 0) {
  #     return(div(class = "alert alert-warning", "No se encontró el archivo de datos"))
  #   }
  #   
  #   if(input$banco_geo == "TODOS LOS BANCOS") {
  #     total <- sum(datos_filtrados_geo()$colocaciones)
  #     provincias <- nrow(datos_filtrados_geo())
  #     HTML(sprintf("
  #     <div style='text-align:center;padding:10px;'>
  #       <i class='fa fa-chart-line' style='font-size:48px;color:#003087;'></i>
  #       <h4>Vista Agregada</h4><hr>
  #       <p><strong>💰 Total Colocaciones:</strong><br>
  #       <span style='color:#003087;font-size:22px;font-weight:bold;'>%.1f MM USD</span></p>
  #       <p><strong>📍 Provincias cubiertas:</strong><br>%d</p>
  #     </div>", total, provincias))
  #   } else {
  #     datos_banco <- datos_colocaciones %>% filter(ENTIDAD == input$banco_geo)
  #     total <- sum(datos_banco$MONTO_MM)
  #     provincias <- n_distinct(datos_banco$PROVINCIA)
  #     participacion <- ifelse(exists("totales_banco") && nrow(totales_banco) > 0, 
  #                             (total / sum(totales_banco$TOTAL_MM)) * 100, 0)
  #     
  #     HTML(sprintf("
  #     <div style='text-align:center;padding:10px;'>
  #       <i class='fa fa-university' style='font-size:48px;color:#003087;'></i>
  #       <h3>%s</h3><hr>
  #       <p><strong>💰 Total:</strong><br><span style='color:#003087;font-size:22px;font-weight:bold;'>%.1f MM USD</span></p>
  #       <p><strong>📊 Participación:</strong><br>%.1f%%</p>
  #       <p><strong>📍 Provincias:</strong><br>%d</p>
  #     </div>", input$banco_geo, total, participacion, provincias))
  #   }
  # })
  # 
  # # Top 5 provincias
  # output$top_provincias_geo <- renderTable({
  #   req(datos_filtrados_geo())
  #   datos_filtrados_geo() %>%
  #     arrange(desc(colocaciones)) %>%
  #     head(5) %>%
  #     mutate(colocaciones = round(colocaciones, 1)) %>%
  #     select(Provincia = PROVINCIA, `MM USD` = colocaciones)
  # })
  # 
  # # Tabla completa
  # output$tabla_colocaciones_geo <- renderDT({
  #   req(datos_filtrados_geo())
  #   datos_filtrados_geo() %>%
  #     arrange(desc(colocaciones)) %>%
  #     mutate(colocaciones = round(colocaciones, 1)) %>%
  #     select(Provincia = PROVINCIA, `Colocaciones (MM USD)` = colocaciones) %>%
  #     datatable(options = list(pageLength = 10, dom = 'Bfrtip', buttons = c('copy', 'csv', 'excel')),
  #               rownames = FALSE, class = 'cell-border stripe hover') %>%
  #     formatStyle("Colocaciones (MM USD)",
  #                 background = styleColorBar(c(0, max(.$`Colocaciones (MM USD)`)), "#003087"),
  #                 backgroundSize = '100% 90%', backgroundRepeat = 'no-repeat')
  # })
  # 
  # # Resetear filtros
  # observeEvent(input$reset_geo, {
  #   updateSelectInput(session, "banco_geo", selected = "BP PACIFICO")
  #   updateSelectInput(session, "provincia_geo", selected = "Todas")
  # })
  
  # ============================================================================
  # ANÁLISIS TEXTUAL PARA INTERPRETACIÓN - BALANCE GENERAL
  # ============================================================================
  
  output$analisis_estructura_financiera <- renderUI({
    # Calcular variaciones
    var_activo_abs <- bp$activo[5] - bp$activo[1]
    var_activo_rel <- (var_activo_abs / bp$activo[1]) * 100
    var_pasivo_abs <- bp$pasivo[5] - bp$pasivo[1]
    var_pasivo_rel <- (var_pasivo_abs / bp$pasivo[1]) * 100
    var_patrimonio_abs <- bp$patrimonio[5] - bp$patrimonio[1]
    var_patrimonio_rel <- (var_patrimonio_abs / bp$patrimonio[1]) * 100
    
    # Calcular coeficientes de variación (estabilidad)
    cv_activo <- sd(bp$activo) / mean(bp$activo) * 100
    cv_pasivo <- sd(bp$pasivo) / mean(bp$pasivo) * 100
    cv_patrimonio <- sd(bp$patrimonio) / mean(bp$patrimonio) * 100
    
    # Determinar tendencias
    tendencia_activo <- ifelse(bp$activo[5] > bp$activo[1], "crecimiento sostenido", "contracción")
    tendencia_pasivo <- ifelse(bp$pasivo[5] > bp$pasivo[1], "crecimiento", "reducción")
    tendencia_patrimonio <- ifelse(bp$patrimonio[5] > bp$patrimonio[1], "fortalecimiento patrimonial", "debilitamiento patrimonial")
    
    # Identificar años atípicos
    media_activo <- mean(bp$activo)
    atipicos_activo <- which(abs(bp$activo - media_activo) > 2 * sd(bp$activo))
    años_atipicos <- if(length(atipicos_activo) > 0) paste(years[atipicos_activo], collapse = " y ") else "ninguno"
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>Activo</strong> del Banco del Pacífico experimentó una variación absoluta de <strong>%.1f MM USD</strong> 
      entre 2021 y 2025, lo que representa un crecimiento del <strong>%.1f%%</strong> en el período analizado. 
      Esta evolución refleja una tendencia de <strong>%s</strong>, con un punto de inflexión notable a partir de 2023, 
      año en el que el activo comenzó una trayectoria ascendente acelerada que lo llevó de 7,005 MM USD en 2023 a 
      9,877 MM USD en 2025, un incremento del 41%% en solo dos años.</p>
      
      <p>La serie del Activo presenta un coeficiente de variación del <strong>%.1f%%</strong>, lo que indica una 
      <strong>volatilidad moderada</strong> durante el período. Los años %s se identifican como valores atípicos, 
      marcando el inicio de una nueva fase de expansión. Esta variabilidad está explicada principalmente por el 
      comportamiento de la <strong>Cartera de Créditos</strong>, que pasó de representar el 60.9%% del activo en 
      2021 al 65.9%% en 2025, y de las <strong>Inversiones</strong>, que crecieron un 90.4%% en el mismo período.</p>
      
      <p>El <strong>Pasivo</strong> mostró un comportamiento similar, con un crecimiento absoluto de %.1f MM USD 
      (%.1f%%), pasando de 6,231 MM USD a 8,764 MM USD. La tendencia es de <strong>%s</strong>, con una variabilidad 
      del %.1f%%. Las <strong>Obligaciones con el Público</strong> constituyen el componente principal del pasivo, 
      representando consistentemente más del 87%% del total. Este rubro creció un 43.4%% en el período, impulsado 
      principalmente por los depósitos a plazo y de ahorro.</p>
      
      <p>El <strong>Patrimonio</strong> registró el crecimiento más significativo en términos relativos, con un 
      aumento del <strong>%.1f%%</strong> (%.1f MM USD), pasando de 819 MM USD a 1,113 MM USD. Esta <strong>%s</strong> 
      se explica por la acumulación de utilidades, que pasaron de ser marginales en 2021 (5.7 MM USD) a representar 
      213.6 MM USD en 2025, y por el incremento en las reservas, que crecieron un 26.5%% en el quinquenio. 
      La baja variabilidad del patrimonio (CV = %.1f%%) indica un crecimiento consistente y planificado.</p>
    </div>
  ", var_activo_abs, var_activo_rel, tendencia_activo, cv_activo, años_atipicos,
                 var_pasivo_abs, var_pasivo_rel, tendencia_pasivo, cv_pasivo,
                 var_patrimonio_abs, var_patrimonio_rel, tendencia_patrimonio, cv_patrimonio))
  })
  
  output$analisis_intermediacion_financiera <- renderUI({
    # Calcular variaciones
    var_cartera_abs <- bp$cartera_bruta[5] - bp$cartera_bruta[1]
    var_cartera_rel <- (var_cartera_abs / bp$cartera_bruta[1]) * 100
    var_oblig_abs <- bp$oblig_publico[5] - bp$oblig_publico[1]
    var_oblig_rel <- (var_oblig_abs / bp$oblig_publico[1]) * 100
    var_interm_abs <- bp$intermediacion[5] - bp$intermediacion[1]
    
    # Calcular coeficientes de variación
    cv_cartera <- sd(bp$cartera_bruta) / mean(bp$cartera_bruta) * 100
    cv_oblig <- sd(bp$oblig_publico) / mean(bp$oblig_publico) * 100
    
    # Determinar año pico de intermediación
    pico_interm <- max(bp$intermediacion)
    año_pico <- years[which.max(bp$intermediacion)]
    
    # Comparación con sistema
    interm_sis_2025 <- sis$cartera_bruta[5] / sis$oblig_publico[5] * 100
    brecha_interm <- bp$intermediacion[5] - interm_sis_2025
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>La <strong>Cartera Bruta</strong> del Banco del Pacífico experimentó un crecimiento notable de 
      <strong>%.1f MM USD</strong> entre 2021 y 2025, equivalente a un incremento del <strong>%.1f%%</strong>. 
      Este dinamismo es superior al observado en el sistema financiero en su conjunto, donde el crecimiento fue del 
      53.2%%. La serie muestra una variabilidad moderada (CV = %.1f%%), con un crecimiento particularmente acelerado 
      en 2024 y 2025, años en los que la cartera aumentó un 12.1%% y 19.3%% respectivamente. Este comportamiento 
      refleja una estrategia agresiva de expansión crediticia, enfocada principalmente en los segmentos comercial 
      y de consumo.</p>
      
      <p>Las <strong>Obligaciones con el Público</strong>, que constituyen la principal fuente de financiamiento del 
      banco, crecieron <strong>%.1f MM USD</strong> (%.1f%%) en el período, pasando de 5,472 MM USD a 7,848 MM USD. 
      La serie es altamente estable (CV = %.1f%%), con un crecimiento consistente año tras año, excepto por una 
      ligera contracción en 2022. Los depósitos a plazo y de ahorro fueron los principales impulsores de este 
      crecimiento, reflejando la confianza del público en la institución.</p>
      
      <p>El <strong>Indicador de Intermediación Financiera</strong>, que mide la proporción de los recursos captados 
      del público que se destinan a créditos, pasó de <strong>78.5%% a 82.9%%</strong> entre 2021 y 2025, un aumento 
      de %.1f puntos porcentuales. El valor máximo se alcanzó en %d, con un pico de %.1f%%, lo que evidencia una 
      utilización óptima de los recursos captados. En 2025, el indicador se sitúa %.1f puntos porcentuales por 
      debajo del promedio del sistema (%.1f%%), lo que sugiere que aún existe espacio para mejorar la eficiencia 
      en la canalización de recursos hacia el crédito.</p>
      
      <p>La evolución de la intermediación refleja un <strong>equilibrio entre crecimiento y estabilidad</strong>: 
      la cartera ha crecido a un ritmo superior al de las obligaciones, lo que ha permitido mejorar el indicador 
      de intermediación sin comprometer la liquidez del banco.</p>
    </div>
  ", var_cartera_abs, var_cartera_rel, cv_cartera,
                 var_oblig_abs, var_oblig_rel, cv_oblig,
                 var_interm_abs, año_pico, pico_interm, abs(brecha_interm), interm_sis_2025))
  })
  
  output$analisis_calidad_cartera <- renderUI({
    # Calcular variaciones
    var_pv_abs <- bp$cartera_pv[5] - bp$cartera_pv[1]
    var_pv_rel <- (var_pv_abs / bp$cartera_pv[1]) * 100
    var_imp_abs <- bp$cartera_imp[5] - bp$cartera_imp[1]
    var_imp_rel <- (var_imp_abs / bp$cartera_imp[1]) * 100
    var_morosidad_abs <- bp$morosidad[5] - bp$morosidad[1]
    var_cobertura_abs <- bp$cobertura[5] - bp$cobertura[1]
    
    # Identificar año pico de morosidad
    pico_morosidad <- max(bp$morosidad)
    año_pico <- years[which.max(bp$morosidad)]
    
    # Calcular variabilidad
    cv_morosidad <- sd(bp$morosidad) / mean(bp$morosidad) * 100
    
    # Comparación con sistema
    morosidad_sis_2025 <- sis$cartera_imp[5] / sis$cartera_bruta[5] * 100
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>La <strong>Cartera por Vencer</strong>, que representa los créditos sanos que se encuentran al día en sus pagos, 
      creció <strong>%.1f MM USD</strong> entre 2021 y 2025, lo que equivale a un incremento del <strong>%.1f%%</strong>. 
      Este crecimiento es consistente con la expansión general de la cartera y refleja la capacidad del banco para 
      colocar nuevos créditos manteniendo estándares de calidad aceptables. La participación de la cartera por vencer 
      sobre el total se mantuvo estable alrededor del 88%% durante todo el período.</p>
      
      <p>La <strong>Cartera Improductiva</strong>, que incluye los créditos que no devengan intereses y los vencidos, 
      aumentó en términos absolutos en <strong>%.1f MM USD</strong> (%.1f%%) entre 2021 y 2025, pero con un comportamiento 
      no lineal. La serie alcanzó su punto máximo en 2023-2024, con valores de 186 MM USD y 188 MM USD respectivamente, 
      para luego reducirse significativamente en 2025 a 165 MM USD. Esta reducción del 12.4%% entre 2024 y 2025 es un 
      indicador positivo que sugiere la efectividad de las estrategias de recuperación implementadas.</p>
      
      <p>La <strong>Tasa de Morosidad</strong> pasó de <strong>2.65%% en 2021 a 2.54%% en 2025</strong>, una reducción 
      de %.2f puntos porcentuales. La serie alcanzó su nivel más crítico en %d, con una morosidad del %.2f%%, para 
      luego mostrar una mejora sostenida. El coeficiente de variación de la morosidad es del %.1f%%, lo que indica una 
      <strong>volatilidad moderada</strong>, con un pico atípico en 2023. En 2025, la morosidad del Banco del Pacífico 
      se sitúa %.2f puntos porcentuales por debajo del promedio del sistema (%.2f%%), lo que evidencia una gestión 
      del riesgo crediticio superior a la media del mercado.</p>
      
      <p>La <strong>Cobertura de Provisiones</strong> aumentó de <strong>228%% a 244%%</strong> entre 2021 y 2025, 
      un incremento de %.0f puntos porcentuales. Este indicador alcanzó su nivel más bajo en 2023 (178%%) y se 
      recuperó fuertemente en 2025, superando ampliamente el mínimo regulatorio del 100%%. La cobertura actual del 
      banco es 18 puntos porcentuales superior a la del sistema financiero (226%%), lo que refleja una política de 
      <strong>provisionamiento conservador y bien capitalizado</strong>, que protege al banco frente a posibles 
      contingencias crediticias.</p>
    </div>
  ", var_pv_abs, var_pv_rel, var_imp_abs, var_imp_rel,
                 var_morosidad_abs, año_pico, pico_morosidad, cv_morosidad,
                 abs(bp$morosidad[5] - morosidad_sis_2025), morosidad_sis_2025,
                 var_cobertura_abs))
  })
  
  # ============================================================================
  # ANÁLISIS TEXTUAL PARA INTERPRETACIÓN - ESTADO DE RESULTADOS
  # ============================================================================
  
  output$analisis_resultados_er <- renderUI({
    var_ingresos_abs <- bp$ingresos[5] - bp$ingresos[1]
    var_ingresos_rel <- (var_ingresos_abs / bp$ingresos[1]) * 100
    var_gastos_abs <- bp$gastos[5] - bp$gastos[1]
    var_gastos_rel <- (var_gastos_abs / bp$gastos[1]) * 100
    var_utilidad_abs <- bp$utilidad[5] - bp$utilidad[1]
    var_utilidad_rel <- (var_utilidad_abs / abs(bp$utilidad[1])) * 100
    
    cv_utilidad <- sd(bp$utilidad) / mean(bp$utilidad) * 100
    
    # Participación en sistema
    part_utilidad_2025 <- (bp$utilidad[5] / sis$utilidad[5]) * 100
    part_ingresos_2025 <- (bp$ingresos[5] / sis$ingresos[5]) * 100
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>comportamiento de los ingresos y gastos</strong> del Banco del Pacífico entre 2021 y 2025 
      revela una mejora sustancial en la eficiencia operativa. Los <strong>Ingresos Totales</strong> crecieron 
      <strong>%.1f MM USD</strong> (%.1f%%), pasando de 743 MM USD a 1,148 MM USD, mientras que los 
      <strong>Gastos Totales</strong> aumentaron solo <strong>%.1f MM USD</strong> (%.1f%%), de 737 MM USD a 942 MM USD. 
      Esta asimetría en el crecimiento explica en gran medida la extraordinaria evolución de la utilidad.</p>
      
      <p>La <strong>Utilidad Neta</strong> experimentó una transformación notable, pasando de una cifra marginal 
      de <strong>5.7 MM USD en 2021 a 206.1 MM USD en 2025</strong>, un incremento absoluto de %.1f MM USD que 
      representa un crecimiento del <strong>%.0f%%</strong>. Este comportamiento no es lineal: la utilidad despegó 
      a partir de 2022, año en el que alcanzó 108 MM USD, y se ha mantenido en una trayectoria ascendente desde 
      entonces. El coeficiente de variación de la utilidad es del %.1f%%, lo que refleja una <strong>alta volatilidad</strong> 
      explicada por el bajo punto de partida en 2021 y el acelerado crecimiento posterior.</p>
      
      <p>En términos de <strong>participación en el sistema financiero</strong>, el Banco del Pacífico genera el 
      <strong>%.1f%% de la utilidad total del sistema</strong> en 2025, una proporción significativamente superior 
      a su participación en ingresos (%.1f%%). Esta diferencia evidencia que el banco ha logrado una <strong>rentabilidad 
      superior al promedio del mercado</strong>, aprovechando economías de escala y una gestión eficiente de sus 
      recursos.</p>
      
      <p>Los factores que explican este comportamiento son principalmente tres: el crecimiento acelerado del margen 
      bruto financiero, la contención de los gastos operativos y la mejora en la calidad de la cartera que ha 
      permitido reducir las provisiones relativas.</p>
    </div>
  ", var_ingresos_abs, var_ingresos_rel, var_gastos_abs, var_gastos_rel,
                 var_utilidad_abs, var_utilidad_rel, cv_utilidad,
                 part_utilidad_2025, part_ingresos_2025))
  })
  
  output$analisis_mbf_eficiencia <- renderUI({
    var_mbf_abs <- bp$mbf[5] - bp$mbf[1]
    var_mbf_rel <- (var_mbf_abs / bp$mbf[1]) * 100
    var_gastos_op_abs <- bp$gastos_op[5] - bp$gastos_op[1]
    var_gastos_op_rel <- (var_gastos_op_abs / bp$gastos_op[1]) * 100
    var_eficiencia_abs <- bp$eficiencia[5] - bp$eficiencia[1]
    
    # Identificar mejor año de eficiencia
    mejor_eficiencia <- min(bp$eficiencia)
    año_mejor <- years[which.min(bp$eficiencia)]
    
    # Comparación con sistema
    eficiencia_sis_2025 <- sis$gastos_op[5] / sis$mbf[5] * 100
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>Margen Bruto Financiero (MBF)</strong>, que representa la diferencia entre los ingresos y egresos 
      financieros, creció <strong>%.1f MM USD</strong> entre 2021 y 2025, lo que equivale a un incremento del 
      <strong>%.1f%%</strong>. El MBF pasó de 446 MM USD a 648 MM USD, impulsado principalmente por el crecimiento 
      de los ingresos por intereses de la cartera de créditos y de las inversiones. Este margen es el principal 
      generador de valor del banco y su evolución ha sido consistente con la expansión de las operaciones activas.</p>
      
      <p>Los <strong>Gastos de Operación</strong> mostraron una evolución notablemente contenida, con un crecimiento 
      absoluto de solo <strong>%.1f MM USD</strong> (%.1f%%) en el quinquenio. Este comportamiento es particularmente 
      destacable si se considera que la cartera de créditos creció un 51.6%% en el mismo período. La disciplina en 
      el control de gastos se refleja en una reducción de los gastos operativos como proporción del MBF, que pasó 
      del 65.0%% en 2021 al 42.4%% en 2025.</p>
      
      <p>El <strong>Indicador de Eficiencia</strong>, que mide qué proporción del MBF es consumida por los gastos 
      operativos, mejoró dramáticamente de <strong>65.0%% a 42.4%%</strong> entre 2021 y 2025, una reducción de 
      %.1f puntos porcentuales. El mejor registro se alcanzó en %d, con un 39.9%%, un nivel que se acerca al 
      umbral de excelencia del 40%%. En 2025, la eficiencia del Banco del Pacífico es %.1f puntos porcentuales 
      mejor que el promedio del sistema (%.1f%%), lo que demuestra una <strong>gestión operativa superior</strong> 
      y una ventaja competitiva significativa.</p>
      
      <p>Esta mejora en la eficiencia explica en gran medida la transformación de la rentabilidad del banco, 
      ya que cada dólar de MBF generado se traduce en una mayor proporción de utilidad neta.</p>
    </div>
  ", var_mbf_abs, var_mbf_rel, var_gastos_op_abs, var_gastos_op_rel,
                 var_eficiencia_abs, año_mejor, mejor_eficiencia,
                 abs(bp$eficiencia[5] - eficiencia_sis_2025), eficiencia_sis_2025))
  })
  
  output$analisis_provisiones_impuestos <- renderUI({
    var_provisiones_abs <- bp$provisiones[5] - bp$provisiones[1]
    var_provisiones_rel <- (var_provisiones_abs / bp$provisiones[1]) * 100
    var_impuestos_abs <- bp$impuestos[5] - bp$impuestos[1]
    var_impuestos_rel <- (var_impuestos_abs / bp$impuestos[1]) * 100
    
    # Relación provisiones/utilidad
    prov_util_2021 <- (bp$provisiones[1] / bp$utilidad[1]) * 100
    prov_util_2025 <- (bp$provisiones[5] / bp$utilidad[5]) * 100
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>Las <strong>Provisiones</strong> constituyen un componente clave en la gestión del riesgo crediticio 
      y tienen un impacto directo en la rentabilidad. Entre 2021 y 2025, las provisiones aumentaron 
      <strong>%.1f MM USD</strong> (%.1f%%), pasando de 186 MM USD a 193 MM USD. Sin embargo, este crecimiento 
      es inferior al de la cartera de créditos (51.6%%), lo que indica una <strong>mejora en la calidad crediticia</strong> 
      de las nuevas colocaciones. La relación entre provisiones y utilidad neta se redujo drásticamente, pasando 
      de representar más de 32 veces la utilidad en 2021 (cuando la utilidad era marginal) a solo el 93.5%% de 
      la utilidad en 2025.</p>
      
      <p>Los <strong>Impuestos</strong> crecieron de manera significativa, de <strong>6.8 MM USD en 2021 a 
      69.9 MM USD en 2025</strong>, un incremento de %.1f MM USD (%.0f%%). Este crecimiento es una consecuencia 
      directa del aumento en la utilidad antes de impuestos, y refleja la contribución fiscal creciente del 
      banco. La tasa impositiva efectiva se ha mantenido estable alrededor del 25%% de la utilidad antes de 
      impuestos en los últimos años.</p>
      
      <p>El análisis conjunto de provisiones e impuestos revela que el banco ha logrado <strong>transformar 
      su estructura de costos</strong>: mientras que en 2021 las provisiones y los impuestos representaban una 
      carga abrumadora frente a la utilidad, en 2025 la utilidad neta supera ampliamente ambos rubros combinados. 
      Esta evolución es un indicador claro de la <strong>maduración y fortalecimiento financiero</strong> de la 
      institución.</p>
    </div>
  ", var_provisiones_abs, var_provisiones_rel,
                 var_impuestos_abs, var_impuestos_rel))
  })
  
  # ============================================================================
  # ANÁLISIS TEXTUAL PARA INTERPRETACIÓN - INDICADORES FINANCIEROS
  # ============================================================================
  
  output$analisis_rentabilidad_indicadores <- renderUI({
    var_roe_abs <- bp$roe[5] - bp$roe[1]
    var_roa_abs <- bp$roa[5] - bp$roa[1]
    
    # Comparación con sistema
    roe_sis_2025 <- sis$roe[5]
    roa_sis_2025 <- sis$roa[5]
    
    # Identificar año de despegue
    año_despegue_roe <- years[which(bp$roe > 10)[1]]
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>Retorno sobre Patrimonio (ROE)</strong> del Banco del Pacífico experimentó una transformación 
      extraordinaria, pasando de un magro <strong>0.70%% en 2021 a un sólido 18.52%% en 2025</strong>, un aumento 
      de %.1f puntos porcentuales. El despegue de la rentabilidad patrimonial ocurrió a partir de %d, año en el 
      que el ROE superó el umbral del 10%%. Desde entonces, el indicador se ha mantenido en una tendencia 
      consistentemente alcista, alcanzando su máximo histórico en 2025. En comparación con el sistema financiero, 
      cuyo ROE en 2025 es del 12.03%%, el Banco del Pacífico supera al promedio en 6.5 puntos porcentuales, 
      lo que evidencia una <strong>rentabilidad patrimonial excepcional</strong>.</p>
      
      <p>El <strong>Retorno sobre Activos (ROA)</strong> muestra una evolución paralela, aunque con una magnitud 
      menor por su naturaleza. El ROA pasó de <strong>0.08%% en 2021 a 2.09%% en 2025</strong>, un incremento de 
      %.2f puntos porcentuales. Este indicador refleja la capacidad del banco para generar utilidades a partir 
      de sus activos totales. Al igual que el ROE, el ROA del banco supera ampliamente al promedio del sistema 
      (1.23%% en 2025), con una ventaja de 0.86 puntos porcentuales.</p>
      
      <p>La <strong>disparidad entre el ROE y el ROA</strong> (18.5%% vs 2.1%%) se explica por el apalancamiento 
      financiero del banco, que tiene un patrimonio que representa aproximadamente el 11.3%% de sus activos. 
      Este apalancamiento amplifica la rentabilidad patrimonial cuando el ROA es positivo, como ha sido el caso 
      en los últimos años. La <strong>tendencia claramente ascendente</strong> de ambos indicadores, con una 
      variabilidad moderada en los últimos tres años, sugiere que la mejora en la rentabilidad es estructural 
      y sostenible.</p>
    </div>
  ", var_roe_abs, año_despegue_roe, 
                 var_roa_abs))
  })
  
  output$analisis_eficiencia_liquidez <- renderUI({
    var_eficiencia_abs <- bp$eficiencia[5] - bp$eficiencia[1]
    var_liquidez_abs <- bp$liquidez[5] - bp$liquidez[1]
    
    # Comparación con sistema
    eficiencia_sis_2025 <- sis$eficiencia[5]
    liquidez_sis_2025 <- sis$liquidez[5]
    
    # Identificar mejor año de eficiencia
    mejor_eficiencia <- min(bp$eficiencia)
    año_mejor <- years[which.min(bp$eficiencia)]
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>Indicador de Eficiencia</strong> muestra una mejora notable durante el período analizado, 
      pasando de <strong>65.03%% en 2021 a 42.40%% en 2025</strong>, una reducción de %.1f puntos porcentuales. 
      El mejor registro se alcanzó en %d, con un 39.9%%, un nivel que se acerca al estándar de excelencia 
      internacional del 40%%. Esta evolución refleja una <strong>disciplina rigurosa en el control de gastos</strong> 
      combinada con un crecimiento acelerado del margen bruto financiero. El banco es significativamente más 
      eficiente que el sistema financiero en su conjunto, que registró una eficiencia del 49.78%% en 2025, 
      una ventaja de 7.4 puntos porcentuales.</p>
      
      <p>El <strong>Indicador de Liquidez</strong>, que mide la capacidad del banco para hacer frente a sus 
      obligaciones de corto plazo, experimentó una <strong>reducción de %.1f puntos porcentuales</strong> entre 
      2021 y 2025, pasando de 36.07%% a 22.88%%. Esta disminución refleja una estrategia deliberada de 
      <strong>optimización de la liquidez en favor de una mayor rentabilidad</strong>, canalizando una mayor 
      proporción de los fondos disponibles hacia la colocación de créditos y las inversiones. A pesar de esta 
      reducción, el indicador se mantiene en niveles saludables y superiores al promedio del sistema, que en 
      2025 se sitúa en 20.25%%.</p>
      
      <p>La <strong>relación entre eficiencia y liquidez</strong> revela una estrategia coherente: el banco ha 
      reducido su posición de liquidez para mejorar su rentabilidad, pero lo ha hecho de manera controlada, 
      manteniéndose por encima de los estándares del mercado. Esta combinación de <strong>alta eficiencia y 
      liquidez adecuada</strong> constituye una posición competitiva sólida frente a sus pares.</p>
    </div>
  ", var_eficiencia_abs, año_mejor, mejor_eficiencia,
                 abs(var_liquidez_abs)))
  })
  
  output$analisis_riesgo_crediticio <- renderUI({
    var_morosidad_abs <- bp$morosidad[5] - bp$morosidad[1]
    var_cobertura_abs <- bp$cobertura[5] - bp$cobertura[1]
    
    # Identificar pico de morosidad
    pico_morosidad <- max(bp$morosidad)
    año_pico <- years[which.max(bp$morosidad)]
    
    # Comparación con sistema
    morosidad_sis_2025 <- sis$morosidad[5]
    cobertura_sis_2025 <- sis$cobertura[5]
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>La <strong>Tasa de Morosidad</strong> del Banco del Pacífico experimentó una evolución no lineal, 
      alcanzando su nivel máximo de <strong>3.82%% en %d</strong> para luego reducirse significativamente a 
      <strong>2.54%% en 2025</strong>. Esta reducción de %.2f puntos porcentuales entre 2023 y 2025 representa 
      una mejora del 33.5%% en términos relativos y refleja la efectividad de las estrategias de recuperación 
      y admisión de crédito implementadas. En 2025, la morosidad del banco se sitúa 0.39 puntos porcentuales 
      por debajo del promedio del sistema (2.93%%), lo que indica una <strong>gestión del riesgo crediticio 
      superior a la media del mercado</strong>.</p>
      
      <p>La <strong>Cobertura de Provisiones</strong> muestra un comportamiento inversamente relacionado con la 
      morosidad. Este indicador alcanzó su nivel más bajo en 2023 (178.03%%), coincidiendo con el pico de 
      morosidad, y se recuperó fuertemente hasta alcanzar <strong>243.97%% en 2025</strong>, un aumento de 
      66 puntos porcentuales en dos años. La cobertura actual del banco supera ampliamente el mínimo regulatorio 
      del 100%% y es 17 puntos porcentuales superior a la del sistema financiero (226.52%%).</p>
      
      <p>Esta combinación de <strong>baja morosidad y alta cobertura</strong> refleja una política conservadora 
      de provisionamiento que protege al banco frente a posibles contingencias crediticias. La relación entre 
      ambos indicadores sugiere que el banco no solo ha mejorado la calidad de su cartera, sino que también 
      ha fortalecido sus reservas para enfrentar eventuales deterioros, lo que constituye una <strong>posición 
      de fortaleza financiera</strong>.</p>
    </div>
  ", año_pico, pico_morosidad, abs(var_morosidad_abs),
                 var_cobertura_abs))
  })
  
  output$analisis_comparativo_sistema <- renderUI({
    # Calcular ratios de participación
    part_activo <- (bp$activo[5] / sis$activo[5]) * 100
    part_utilidad <- (bp$utilidad[5] / sis$utilidad[5]) * 100
    part_cartera <- (bp$cartera_bruta[5] / sis$cartera_bruta[5]) * 100
    
    # Calcular diferenciales de rentabilidad
    diferencial_roe <- bp$roe[5] - sis$roe[5]
    diferencial_roa <- bp$roa[5] - sis$roa[5]
    diferencial_eficiencia <- sis$eficiencia[5] - bp$eficiencia[5]
    
    HTML(sprintf("
    <div style='line-height:1.7; color:#2C3E50; text-align:justify;'>
      <p>El <strong>posicionamiento competitivo del Banco del Pacífico</strong> dentro del sistema financiero 
      ecuatoriano se ha fortalecido significativamente durante el período 2021-2025. Con una participación 
      del <strong>%.1f%% en el activo total</strong> y del <strong>%.1f%% en la cartera de créditos</strong>, 
      el banco se consolida como uno de los actores principales del mercado. Sin embargo, su participación 
      en la utilidad del sistema alcanza el <strong>%.1f%%</strong>, muy por encima de su peso patrimonial 
      y de activos, lo que evidencia una <strong>rentabilidad superior a la media</strong>.</p>
      
      <p>En términos de <strong>rentabilidad relativa</strong>, el Banco del Pacífico supera al sistema 
      financiero por un amplio margen: el ROE es %.1f puntos porcentuales superior (%.1f%% vs %.1f%%) y el 
      ROA es %.2f puntos porcentuales superior (%.2f%% vs %.2f%%). Esta ventaja competitiva se explica 
      principalmente por una <strong>eficiencia operativa notablemente mejor</strong>, con un indicador 
      de eficiencia %.1f puntos porcentuales inferior al promedio del sistema (%.1f%% vs %.1f%%), lo que 
      significa que el banco gasta proporcionalmente menos en operación por cada dólar de margen financiero 
      generado.</p>
      
      <p>En el ámbito de la <strong>gestión del riesgo crediticio</strong>, el banco también muestra una 
      posición ventajosa, con una morosidad inferior en 0.4 puntos porcentuales y una cobertura de provisiones 
      superior en 17.5 puntos porcentuales. Esta combinación de <strong>alta rentabilidad, eficiencia superior 
      y gestión conservadora del riesgo</strong> posiciona al Banco del Pacífico como una de las entidades 
      financieras más sólidas y bien gestionadas del sistema financiero ecuatoriano.</p>
    </div>
  ", part_activo, part_cartera, part_utilidad,
                 diferencial_roe, bp$roe[5], sis$roe[5],
                 diferencial_roa, bp$roa[5], sis$roa[5],
                 diferencial_eficiencia, bp$eficiencia[5], sis$eficiencia[5]))
  })
  
  
  # ============================================================================
  # ANÁLISIS GEOGRÁFICO - MAPA DE COLOCACIONES Y COMPARATIVA
  # ============================================================================
  
  # --- Datos filtrados para el mapa ---
  datos_filtrados_geo <- reactive({
    req(exists("datos_colocaciones"))
    if(nrow(datos_colocaciones) == 0) return(data.frame())
    
    df <- datos_colocaciones
    
    if(input$banco_geo != "TODOS LOS BANCOS") {
      df <- df %>% filter(ENTIDAD == input$banco_geo)
    }
    
    if(input$provincia_geo != "Todas") {
      df <- df %>% filter(PROVINCIA == input$provincia_geo)
    }
    
    df %>%
      group_by(PROVINCIA, PROVINCIA_MAPA) %>%
      summarise(colocaciones = sum(MONTO_MM, na.rm = TRUE), .groups = 'drop')
  })
  
  # --- MAPA INTERACTIVO (CON HOVER QUE MUESTRA EL VALOR) ---
  output$mapa_geo <- renderHighchart({
    req(datos_filtrados_geo())
    df <- datos_filtrados_geo()
    if(nrow(df) == 0) {
      return(highchart() %>% hc_title(text = "No hay datos para los filtros seleccionados"))
    }
    
    valores <- df$colocaciones
    min_val <- ifelse(min(valores) > 0, min(valores) * 0.9, 0)
    max_val <- max(valores) * 1.1
    
    # Formatear números para el tooltip
    df$tooltip_valor <- round(df$colocaciones, 1)
    
    highchart(type = "map") %>%
      hc_add_series_map(
        map = download_map_data("countries/ec/ec-all"),
        df = df,
        value = "colocaciones",
        joinBy = c("name", "PROVINCIA_MAPA"),
        name = "Colocaciones",
        dataLabels = list(enabled = TRUE, format = "{point.name}", style = list(fontSize = "9px")),
        tooltip = list(
          pointFormat = "<b>{point.name}</b><br>💰 <b>{point.colocaciones:.1f} MM USD</b><br>📊 Participación: {point.percentage:.1f}%"
        ),
        borderColor = "#ffffff", 
        borderWidth = 0.5
      ) %>%
      hc_colorAxis(
        min = min_val, 
        max = max_val, 
        type = "linear",
        stops = color_stops(5, c("#2ecc71", "#f1c40f", "#e67e22", "#e74c3c", "#8e44ad"))
      ) %>%
      hc_title(text = paste("Colocaciones -", input$banco_geo)) %>%
      hc_subtitle(text = "Millones de USD por provincia | Hover para ver valor") %>%
      hc_legend(
        title = list(text = "MM USD"), 
        align = "right", 
        verticalAlign = "top", 
        layout = "vertical",
        valueDecimals = 1
      ) %>%
      hc_mapNavigation(enabled = TRUE) %>%
      hc_exporting(enabled = TRUE) %>%
      hc_chart(backgroundColor = "white") %>%
      hc_tooltip(
        shared = FALSE,
        valueDecimals = 1,
        valueSuffix = " MM USD"
      )
  })
  
  # --- Información del banco ---
  output$info_banco_geo <- renderUI({
    req(exists("datos_colocaciones"))
    if(nrow(datos_colocaciones) == 0) {
      return(div(class = "alert alert-warning", "⚠️ No se encontró el archivo de datos. Verifique la ruta."))
    }
    
    if(input$banco_geo == "TODOS LOS BANCOS") {
      total <- sum(datos_filtrados_geo()$colocaciones, na.rm = TRUE)
      provincias <- nrow(datos_filtrados_geo())
      promedio <- ifelse(provincias > 0, total / provincias, 0)
      
      HTML(sprintf("
      <div style='text-align:center;padding:10px;'>
        <i class='fa fa-chart-line' style='font-size:48px;color:#003087;'></i>
        <h4>Vista Agregada</h4>
        <hr>
        <p><strong>💰 Total Colocaciones:</strong><br>
        <span style='color:#003087;font-size:22px;font-weight:bold;'>%.1f MM USD</span></p>
        <p><strong>📍 Provincias cubiertas:</strong><br>%d</p>
        <p><strong>📊 Colocación promedio por provincia:</strong><br>%.1f MM USD</p>
      </div>", total, provincias, promedio))
    } else {
      datos_banco <- datos_colocaciones %>% filter(ENTIDAD == input$banco_geo)
      total <- sum(datos_banco$MONTO_MM, na.rm = TRUE)
      provincias <- n_distinct(datos_banco$PROVINCIA)
      promedio <- ifelse(provincias > 0, total / provincias, 0)
      
      participacion <- ifelse(exists("totales_banco") && nrow(totales_banco) > 0 && sum(totales_banco$TOTAL_MM) > 0,
                              (total / sum(totales_banco$TOTAL_MM, na.rm = TRUE)) * 100, 0)
      
      ranking <- which(totales_banco$ENTIDAD == input$banco_geo)
      posicion <- ifelse(length(ranking) > 0, ranking, NA)
      
      HTML(sprintf("
      <div style='text-align:center;padding:10px;'>
        <i class='fa fa-university' style='font-size:48px;color:#003087;'></i>
        <h3>%s</h3>
        <hr>
        <p><strong>💰 Total Colocaciones:</strong><br>
        <span style='color:#003087;font-size:22px;font-weight:bold;'>%.1f MM USD</span></p>
        <p><strong>📊 Participación en el sistema:</strong><br>%.1f%%</p>
        <p><strong>📍 Provincias con presencia:</strong><br>%d</p>
        <p><strong>📊 Colocación promedio por provincia:</strong><br>%.1f MM USD</p>
        %s
      </div>", 
                   input$banco_geo, total, participacion, provincias, promedio,
                   ifelse(!is.na(posicion), sprintf("<p><strong>🏆 Ranking:</strong><br>#%d de %d bancos</p>", posicion, nrow(totales_banco)), "")))
    }
  })
  
  # --- Top 5 provincias ---
  output$top_provincias_geo <- renderTable({
    req(datos_filtrados_geo())
    datos_filtrados_geo() %>%
      arrange(desc(colocaciones)) %>%
      head(5) %>%
      mutate(colocaciones = round(colocaciones, 1)) %>%
      select(Provincia = PROVINCIA, `MM USD` = colocaciones)
  })
  
  # --- Tabla completa de colocaciones ---
  output$tabla_colocaciones_geo <- renderDT({
    req(datos_filtrados_geo())
    total <- sum(datos_filtrados_geo()$colocaciones)
    
    datos_filtrados_geo() %>%
      arrange(desc(colocaciones)) %>%
      mutate(
        colocaciones = round(colocaciones, 1),
        participacion = paste0(round(colocaciones / total * 100, 1), "%")
      ) %>%
      select(Provincia = PROVINCIA, `Colocaciones (MM USD)` = colocaciones, `Participación` = participacion) %>%
      datatable(
        options = list(pageLength = 10, dom = 'Bfrtip', buttons = c('copy', 'csv', 'excel')),
        rownames = FALSE, 
        class = 'cell-border stripe hover'
      ) %>%
      formatStyle("Colocaciones (MM USD)",
                  background = styleColorBar(c(0, max(.$`Colocaciones (MM USD)`)), "#003087"),
                  backgroundSize = '100% 90%', backgroundRepeat = 'no-repeat')
  })
  
  # --- Resetear filtros ---
  observeEvent(input$reset_geo, {
    updateSelectInput(session, "banco_geo", selected = "BP PACIFICO")
    updateSelectInput(session, "provincia_geo", selected = "Todas")
  })
  
  # ============================================================================
  # COMPARATIVA DE BANCOS
  # ============================================================================
  
  # --- Gráfico de barras Top 10 ---
  output$barras_top10 <- renderHighchart({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) return(highchart() %>% hc_title(text = "No hay datos"))
    
    top10 <- head(totales_banco, 10)
    
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_xAxis(
        categories = top10$ENTIDAD,
        title = list(text = ""),
        labels = list(rotation = -45, style = list(fontSize = "10px"))
      ) %>%
      hc_yAxis(title = list(text = "Colocaciones (MM USD)"), labels = list(format = "{value} MM")) %>%
      hc_add_series(
        name = "Colocaciones",
        data = round(top10$TOTAL_MM, 1),
        color = "#003087",
        dataLabels = list(enabled = TRUE, format = "{y:.0f}", style = list(fontWeight = "bold", fontSize = "10px"))
      ) %>%
      hc_title(text = "Top 10 Bancos con Mayor Colocación") %>%
      hc_subtitle(text = "Millones de USD") %>%
      hc_plotOptions(column = list(borderRadius = 4, borderWidth = 0, cursor = "pointer")) %>%
      hc_tooltip(pointFormat = "<b>{point.y:.1f} MM USD</b><br>Participación: {point.percentage:.1f}%") %>%
      hc_exporting(enabled = TRUE) %>%
      hc_chart(backgroundColor = "white")
  })
  
  # --- Gráfico de participación (Pie) ---
  output$pie_participacion <- renderHighchart({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) return(highchart() %>% hc_title(text = "No hay datos"))
    
    # Top 8 + Otros
    top8 <- head(totales_banco, 8)
    otros_total <- sum(totales_banco$TOTAL_MM[9:nrow(totales_banco)]) / sum(totales_banco$TOTAL_MM) * 100
    
    datos_pie <- data.frame(
      name = c(as.character(top8$ENTIDAD), "Otros"),
      y = c(top8$TOTAL_MM / sum(totales_banco$TOTAL_MM) * 100, otros_total)
    )
    
    highchart() %>%
      hc_chart(type = "pie", backgroundColor = "white") %>%
      hc_add_series(
        name = "Participación",
        data = datos_pie,
        colors = c("#003087", "#1a5bbf", "#3385e6", "#4da6ff", "#66b3ff", "#80bfff", "#99ccff", "#b3d9ff", "#e0e0e0"),
        dataLabels = list(enabled = TRUE, format = "{point.name}: {point.percentage:.1f}%", style = list(fontSize = "10px"))
      ) %>%
      hc_title(text = "Participación por Banco") %>%
      hc_subtitle(text = "Porcentaje del total de colocaciones") %>%
      hc_tooltip(pointFormat = "<b>{point.name}</b><br>Participación: {point.y:.1f}%") %>%
      hc_exporting(enabled = TRUE)
  })
  
  # --- Tabla completa de bancos ---
  output$tabla_bancos_geo <- renderDT({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) return(datatable(data.frame(Mensaje = "No hay datos")))
    
    total_sistema <- sum(totales_banco$TOTAL_MM)
    
    totales_banco %>%
      mutate(
        TOTAL_MM = round(TOTAL_MM, 1),
        PARTICIPACION = paste0(round(TOTAL_MM / total_sistema * 100, 1), "%"),
        MAX_MONTO = round(MAX_MONTO, 1)
      ) %>%
      select(
        `Banco` = ENTIDAD,
        `Total (MM USD)` = TOTAL_MM,
        `Participación` = PARTICIPACION,
        `Provincias` = PROVINCIAS,
        `Máximo (MM USD)` = MAX_MONTO,
        `Provincia Principal` = PROVINCIA_PRINCIPAL
      ) %>%
      datatable(
        options = list(pageLength = 15, dom = 'Bfrtip', buttons = c('copy', 'csv', 'excel')),
        rownames = FALSE,
        class = 'cell-border stripe hover'
      ) %>%
      formatStyle("Total (MM USD)",
                  background = styleColorBar(c(0, max(.$`Total (MM USD)`)), "#003087"),
                  backgroundSize = '100% 90%', backgroundRepeat = 'no-repeat')
  })
  
  # --- Texto de concentración de mercado ---
  output$concentracion_texto <- renderUI({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) return(div("No hay datos"))
    
    total <- sum(totales_banco$TOTAL_MM)
    top3 <- sum(head(totales_banco$TOTAL_MM, 3))
    top5 <- sum(head(totales_banco$TOTAL_MM, 5))
    top10 <- sum(head(totales_banco$TOTAL_MM, 10))
    
    hhi <- sum((totales_banco$TOTAL_MM / total * 100)^2)  # Índice Herfindahl-Hirschman
    
    nivel_concentracion <- ifelse(hhi < 1500, "Baja", ifelse(hhi < 2500, "Moderada", "Alta"))
    
    HTML(sprintf("
    <div style='padding:10px;'>
      <h4>📊 Indicadores de Concentración</h4>
      <hr>
      <p><strong>Top 3 bancos</strong> concentran el <strong style='color:#003087;font-size:18px;'>%.1f%%</strong> del mercado</p>
      <p><strong>Top 5 bancos</strong> concentran el <strong style='color:#003087;font-size:18px;'>%.1f%%</strong> del mercado</p>
      <p><strong>Top 10 bancos</strong> concentran el <strong style='color:#003087;font-size:18px;'>%.1f%%</strong> del mercado</p>
      <hr>
      <p><strong>📐 Índice HHI:</strong> %.0f</p>
      <p><strong>🏷️ Nivel de concentración:</strong> <span style='color:%s;font-weight:bold;'>%s</span></p>
      <hr>
      <p><small>HHI < 1500: Baja concentración | 1500-2500: Moderada | >2500: Alta</small></p>
    </div>
  ", top3/total*100, top5/total*100, top10/total*100, hhi, 
                 ifelse(nivel_concentracion == "Alta", "#e74c3c", ifelse(nivel_concentracion == "Moderada", "#f1c40f", "#2ecc71")),
                 nivel_concentracion))
  })
  
  # --- Mapa de calor (Bancos vs Provincias Top) ---
  output$heatmap_bancos <- renderHighchart({
    req(exists("datos_colocaciones"))
    if(nrow(datos_colocaciones) == 0) return(highchart() %>% hc_title(text = "No hay datos"))
    
    # Top 10 bancos y Top 8 provincias
    top_bancos <- head(totales_banco$ENTIDAD, 10)
    top_provincias <- datos_colocaciones %>%
      group_by(PROVINCIA) %>%
      summarise(total = sum(MONTO_MM)) %>%
      arrange(desc(total)) %>%
      head(8) %>%
      pull(PROVINCIA)
    
    # Crear matriz de calor
    heatmap_data <- datos_colocaciones %>%
      filter(ENTIDAD %in% top_bancos, PROVINCIA %in% top_provincias) %>%
      group_by(ENTIDAD, PROVINCIA) %>%
      summarise(valor = sum(MONTO_MM, na.rm = TRUE), .groups = 'drop')
    
    # Escalar para colores (log para mejor visualización)
    heatmap_data$valor_log <- log10(heatmap_data$valor + 1)
    
    highchart() %>%
      hc_chart(type = "heatmap", backgroundColor = "white") %>%
      hc_xAxis(categories = top_provincias, title = list(text = "Provincia")) %>%
      hc_yAxis(categories = top_bancos, title = list(text = "Banco"), reversed = TRUE) %>%
      hc_add_series(
        name = "Colocaciones (MM USD)",
        data = heatmap_data %>% 
          mutate(valor_round = round(valor, 1)) %>%
          select(x = PROVINCIA, y = ENTIDAD, value = valor_log, valor_real = valor_round),
        dataLabels = list(enabled = TRUE, format = "{point.valor_real}", style = list(fontSize = "8px"))
      ) %>%
      hc_colorAxis(
        stops = color_stops(5, c("#2ecc71", "#f1c40f", "#e67e22", "#e74c3c", "#8e44ad")),
        type = "linear"
      ) %>%
      hc_title(text = "Mapa de Calor: Top Bancos vs Top Provincias") %>%
      hc_subtitle(text = "Color intensidad = Mayor colocación (MM USD)") %>%
      hc_tooltip(pointFormat = "<b>{point.x}</b> / <b>{point.y}</b><br>💰 Colocaciones: {point.valor_real} MM USD") %>%
      hc_exporting(enabled = TRUE) %>%
      hc_chart(backgroundColor = "white")
  })
  
  
  # ============================================================================
  # COMPARATIVA DE BANCOS - SERVER COMPLETO
  # ============================================================================
  
  # --- Gráfico de barras Top 10 ---
  output$barras_top10 <- renderHighchart({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) {
      return(highchart() %>% hc_title(text = "No hay datos disponibles"))
    }
    
    top10 <- head(totales_banco, 10)
    
    highchart() %>%
      hc_chart(type = "column", backgroundColor = "white") %>%
      hc_xAxis(
        categories = top10$ENTIDAD,
        title = list(text = ""),
        labels = list(rotation = -45, style = list(fontSize = "10px"))
      ) %>%
      hc_yAxis(
        title = list(text = "Colocaciones (MM USD)"),
        labels = list(format = "{value} MM")
      ) %>%
      hc_add_series(
        name = "Colocaciones",
        data = round(top10$TOTAL_MM, 1),
        color = "#003087",
        dataLabels = list(
          enabled = TRUE,
          format = "{y:.0f}",
          style = list(fontWeight = "bold", fontSize = "10px"),
          rotation = -90,
          y = -5
        )
      ) %>%
      hc_title(text = "Top 10 Bancos con Mayor Colocación") %>%
      hc_subtitle(text = "Millones de USD - Datos reales") %>%
      hc_plotOptions(
        column = list(
          borderRadius = 4,
          borderWidth = 0,
          cursor = "pointer",
          pointWidth = 35
        )
      ) %>%
      hc_tooltip(
        pointFormat = "<b>{point.y:.1f} MM USD</b><br>Participación: {point.percentage:.1f}%"
      ) %>%
      hc_exporting(enabled = TRUE)
  })
  
  # --- Gráfico de participación (Pie) ---
  output$pie_participacion <- renderHighchart({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) {
      return(highchart() %>% hc_title(text = "No hay datos disponibles"))
    }
    
    total_sistema <- sum(totales_banco$TOTAL_MM, na.rm = TRUE)
    
    # Top 8 + Otros
    top8 <- head(totales_banco, 8)
    otros_total <- sum(totales_banco$TOTAL_MM[9:nrow(totales_banco)], na.rm = TRUE)
    
    datos_pie <- data.frame(
      name = c(as.character(top8$ENTIDAD), "Otros Bancos"),
      y = c(top8$TOTAL_MM, otros_total)
    )
    
    # Colores para el pie
    colores_pie <- c("#003087", "#1a5bbf", "#3385e6", "#4da6ff", "#66b3ff", "#80bfff", "#99ccff", "#b3d9ff", "#d9d9d9")
    
    highchart() %>%
      hc_chart(type = "pie", backgroundColor = "white") %>%
      hc_add_series(
        name = "Participación",
        data = datos_pie,
        colors = colores_pie,
        size = "80%",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.name}: {point.percentage:.1f}%",
          style = list(fontSize = "10px", fontWeight = "normal"),
          distance = 15
        ),
        showInLegend = TRUE
      ) %>%
      hc_title(text = "Participación por Banco") %>%
      hc_subtitle(text = "Porcentaje del total de colocaciones") %>%
      hc_tooltip(
        pointFormat = "<b>{point.name}</b><br>💰 {point.y:.1f} MM USD<br>📊 Participación: {point.percentage:.1f}%"
      ) %>%
      hc_exporting(enabled = TRUE) %>%
      hc_plotOptions(
        pie = list(
          allowPointSelect = TRUE,
          cursor = "pointer",
          borderWidth = 0
        )
      )
  })
  
  # --- Tabla completa de bancos ---
  output$tabla_bancos_geo <- renderDT({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) {
      return(datatable(data.frame(Mensaje = "No hay datos disponibles"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    total_sistema <- sum(totales_banco$TOTAL_MM, na.rm = TRUE)
    
    # Agregar ranking
    totales_banco_con_ranking <- totales_banco %>%
      mutate(
        RANKING = row_number(),
        TOTAL_MM = round(TOTAL_MM, 1),
        PARTICIPACION = round(TOTAL_MM / total_sistema * 100, 1),
        PARTICIPACION_ACUM = round(cumsum(TOTAL_MM) / total_sistema * 100, 1),
        MAX_MONTO = round(MAX_MONTO, 1)
      ) %>%
      select(
        Ranking = RANKING,
        Banco = ENTIDAD,
        `Total (MM USD)` = TOTAL_MM,
        Participación = PARTICIPACION,
        `Participación Acumulada` = PARTICIPACION_ACUM,
        Provincias = PROVINCIAS,
        `Máximo (MM USD)` = MAX_MONTO,
        `Provincia Principal` = PROVINCIA_PRINCIPAL
      )
    
    datatable(
      totales_banco_con_ranking,
      options = list(
        pageLength = 15,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        columnDefs = list(
          list(className = 'dt-center', targets = '_all'),
          list(width = '5%', targets = 0),
          list(width = '25%', targets = 1),
          list(width = '10%', targets = c(2,3,4,5,6)),
          list(width = '15%', targets = 7)
        )
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover',
      extensions = 'Buttons'
    ) %>%
      formatStyle("Total (MM USD)",
                  background = styleColorBar(c(0, max(totales_banco_con_ranking$`Total (MM USD)`)), "#003087"),
                  backgroundSize = '100% 90%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center') %>%
      formatStyle("Participación",
                  background = styleColorBar(c(0, max(totales_banco_con_ranking$Participación)), "#E8891D"),
                  backgroundSize = '100% 90%',
                  backgroundRepeat = 'no-repeat') %>%
      formatStyle("Ranking",
                  fontWeight = "bold",
                  color = "#003087")
  })
  
  # --- Texto de concentración de mercado ---
  output$concentracion_texto <- renderUI({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) {
      return(div(class = "alert alert-warning", "⚠️ No hay datos disponibles"))
    }
    
    total <- sum(totales_banco$TOTAL_MM, na.rm = TRUE)
    n_bancos <- nrow(totales_banco)
    
    top1 <- totales_banco$TOTAL_MM[1]
    top3 <- sum(head(totales_banco$TOTAL_MM, 3), na.rm = TRUE)
    top5 <- sum(head(totales_banco$TOTAL_MM, 5), na.rm = TRUE)
    top10 <- sum(head(totales_banco$TOTAL_MM, min(10, n_bancos)), na.rm = TRUE)
    
    # Índice Herfindahl-Hirschman (HHI)
    participaciones <- (totales_banco$TOTAL_MM / total) * 100
    hhi <- sum(participaciones^2)
    
    nivel_concentracion <- ifelse(hhi < 1500, "Baja", ifelse(hhi < 2500, "Moderada", "Alta"))
    color_concentracion <- ifelse(nivel_concentracion == "Alta", "#e74c3c", 
                                  ifelse(nivel_concentracion == "Moderada", "#f1c40f", "#2ecc71"))
    
    # Banco líder
    banco_lider <- totales_banco$ENTIDAD[1]
    lider_participacion <- (top1 / total) * 100
    
    HTML(sprintf("
    <div style='padding:15px; background:#f8f9fa; border-radius:8px;'>
      <h4 style='color:#003087; margin-top:0;'>📊 Indicadores de Concentración</h4>
      <hr style='margin:10px 0;'>
      
      <div style='margin-bottom:15px;'>
        <p style='margin:5px 0;'><strong>🏆 Banco líder:</strong> <span style='color:#003087;font-weight:bold;'>%s</span></p>
        <p style='margin:5px 0;'><strong>📈 Participación del líder:</strong> %.1f%%</p>
      </div>
      
      <div style='background:white; padding:10px; border-radius:5px; margin-bottom:10px;'>
        <p style='margin:5px 0;'><strong>Top 3 bancos</strong> concentran el <strong style='color:#003087;font-size:16px;'>%.1f%%</strong> del mercado</p>
        <p style='margin:5px 0;'><strong>Top 5 bancos</strong> concentran el <strong style='color:#003087;font-size:16px;'>%.1f%%</strong> del mercado</p>
        <p style='margin:5px 0;'><strong>Top 10 bancos</strong> concentran el <strong style='color:#003087;font-size:16px;'>%.1f%%</strong> del mercado</p>
      </div>
      
      <hr style='margin:10px 0;'>
      
      <div style='text-align:center;'>
        <p style='margin:5px 0;'><strong>📐 Índice HHI:</strong> <span style='font-size:18px;font-weight:bold;'>%.0f</span></p>
        <p style='margin:5px 0;'><strong>🏷️ Nivel de concentración:</strong> 
          <span style='color:%s;font-weight:bold;background:#f0f0f0;padding:2px 8px;border-radius:12px;'>%s</span>
        </p>
      </div>
      
      <hr style='margin:10px 0;'>
      
      <div style='font-size:11px; color:#666; text-align:center;'>
        <p style='margin:2px 0;'>📌 HHI < 1500: Baja concentración | 1500-2500: Moderada | >2500: Alta</p>
        <p style='margin:2px 0;'>📌 Total de bancos analizados: %d</p>
      </div>
    </div>
  ", 
                 banco_lider, lider_participacion,
                 top3/total*100, top5/total*100, top10/total*100,
                 hhi, color_concentracion, nivel_concentracion,
                 n_bancos))
  })
  
  # --- Mapa de calor (Bancos vs Provincias Top) ---
  output$heatmap_bancos <- renderHighchart({
    req(exists("datos_colocaciones"))
    if(nrow(datos_colocaciones) == 0) {
      return(highchart() %>% hc_title(text = "No hay datos disponibles"))
    }
    
    # Top 10 bancos y Top 8 provincias
    top_bancos <- head(totales_banco$ENTIDAD, 10)
    top_provincias <- datos_colocaciones %>%
      group_by(PROVINCIA) %>%
      summarise(total = sum(MONTO_MM, na.rm = TRUE)) %>%
      arrange(desc(total)) %>%
      head(8) %>%
      pull(PROVINCIA)
    
    # Crear matriz de calor
    heatmap_data <- datos_colocaciones %>%
      filter(ENTIDAD %in% top_bancos, PROVINCIA %in% top_provincias) %>%
      group_by(ENTIDAD, PROVINCIA) %>%
      summarise(valor = sum(MONTO_MM, na.rm = TRUE), .groups = 'drop')
    
    # Escalar para colores (log para mejor visualización)
    heatmap_data$valor_log <- log10(heatmap_data$valor + 1)
    heatmap_data$valor_round <- round(heatmap_data$valor, 1)
    
    # Crear dataframe para highchart
    heatmap_list <- heatmap_data %>%
      mutate(
        x = match(PROVINCIA, top_provincias) - 1,
        y = match(ENTIDAD, top_bancos) - 1
      )
    
    highchart() %>%
      hc_chart(type = "heatmap", backgroundColor = "white") %>%
      hc_xAxis(
        categories = top_provincias,
        title = list(text = "Provincia"),
        labels = list(rotation = -45, style = list(fontSize = "10px"))
      ) %>%
      hc_yAxis(
        categories = top_bancos,
        title = list(text = "Banco"),
        reversed = TRUE,
        labels = list(style = list(fontSize = "9px"))
      ) %>%
      hc_add_series(
        name = "Colocaciones (MM USD)",
        data = heatmap_list %>%
          select(x, y, value = valor_log, valor_real = valor_round),
        type = "heatmap",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.valor_real}",
          style = list(fontSize = "8px", fontWeight = "bold"),
          color = "#333"
        ),
        tooltip = list(
          pointFormat = "<b>{point.x_category}</b> / <b>{point.y_category}</b><br>💰 Colocaciones: <b>{point.valor_real} MM USD</b>"
        )
      ) %>%
      hc_colorAxis(
        stops = color_stops(5, c("#2ecc71", "#f1c40f", "#e67e22", "#e74c3c", "#8e44ad")),
        type = "linear",
        title = list(text = "Intensidad (log)")
      ) %>%
      hc_title(text = "Mapa de Calor: Top Bancos vs Top Provincias") %>%
      hc_subtitle(text = "Color más intenso = Mayor colocación | Log10 escala") %>%
      hc_legend(
        title = list(text = "Log(MM USD)"),
        align = "right",
        verticalAlign = "top",
        layout = "vertical"
      ) %>%
      hc_exporting(enabled = TRUE) %>%
      hc_chart(backgroundColor = "white")
  })
  
  # --- Datos para el radar comparativo ---
  output$radar_comparativo <- renderHighchart({
    req(exists("totales_banco"))
    if(nrow(totales_banco) == 0) {
      return(highchart() %>% hc_title(text = "No hay datos"))
    }
    
    # Seleccionar top 5 bancos para comparar
    top5 <- head(totales_banco, 5)
    
    # Normalizar para radar (0-100)
    max_total <- max(top5$TOTAL_MM)
    max_provincias <- max(top5$PROVINCIAS)
    max_max_monto <- max(top5$MAX_MONTO)
    
    radar_data <- top5 %>%
      mutate(
        nombre = ENTIDAD,
        total_norm = TOTAL_MM / max_total * 100,
        provincias_norm = PROVINCIAS / max_provincias * 100,
        max_norm = MAX_MONTO / max_max_monto * 100,
        promedio_norm = (TOTAL_MM / PROVINCIAS) / (max_total / max_provincias) * 100
      )
    
    highchart() %>%
      hc_chart(polar = TRUE, type = "line", backgroundColor = "white") %>%
      hc_xAxis(
        categories = c("Total Colocaciones", "Cobertura Provincias", "Máximo por Provincia", "Promedio por Provincia"),
        tickmarkPlacement = "on",
        lineWidth = 0
      ) %>%
      hc_yAxis(
        gridLineInterpolation = "polygon",
        lineWidth = 0,
        min = 0,
        max = 100,
        labels = list(format = "{value}%")
      ) %>%
      hc_add_series(
        name = radar_data$nombre[1],
        data = round(as.numeric(radar_data[1, c("total_norm", "provincias_norm", "max_norm", "promedio_norm")]), 1),
        color = "#003087",
        lineWidth = 2,
        marker = list(radius = 4)
      ) %>%
      hc_add_series(
        name = radar_data$nombre[2],
        data = round(as.numeric(radar_data[2, c("total_norm", "provincias_norm", "max_norm", "promedio_norm")]), 1),
        color = "#E8891D",
        lineWidth = 2,
        marker = list(radius = 4)
      ) %>%
      hc_add_series(
        name = radar_data$nombre[3],
        data = round(as.numeric(radar_data[3, c("total_norm", "provincias_norm", "max_norm", "promedio_norm")]), 1),
        color = "#27AE60",
        lineWidth = 2,
        marker = list(radius = 4)
      ) %>%
      hc_add_series(
        name = radar_data$nombre[4],
        data = round(as.numeric(radar_data[4, c("total_norm", "provincias_norm", "max_norm", "promedio_norm")]), 1),
        color = "#8E44AD",
        lineWidth = 2,
        marker = list(radius = 4)
      ) %>%
      hc_add_series(
        name = radar_data$nombre[5],
        data = round(as.numeric(radar_data[5, c("total_norm", "provincias_norm", "max_norm", "promedio_norm")]), 1),
        color = "#C0392B",
        lineWidth = 2,
        marker = list(radius = 4)
      ) %>%
      hc_title(text = "Comparativa Radial - Top 5 Bancos") %>%
      hc_subtitle(text = "Valores normalizados (0-100%). Mayor área = Mejor desempeño") %>%
      hc_tooltip(pointFormat = "<b>{series.name}</b><br>{point.category}: {point.y:.1f}%") %>%
      hc_legend(align = "center", verticalAlign = "bottom", layout = "horizontal") %>%
      hc_exporting(enabled = TRUE)
  })
  
  
  
}

shinyApp(ui, server)