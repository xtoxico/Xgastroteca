# PROYECTO: Xgastroteca (Recetario Personal con IA)

## 1. Visión General

Aplicación móvil (Flutter) y Backend (Go) para guardar, procesar y catalogar recetas de Instagram automáticamente usando IA.
Usuarios: 2 (Entorno de confianza, seguridad básica).

## 2. Stack Tecnológico

- **Mobile:** Flutter (Dart).
- **Backend:** Go (Golang) usando Gin Gonic o Fiber.
- **Base de Datos:** SQLite (Gorm o SQLC). Al ser local y pocos usuarios, es lo más rápido y portable.
- **Infraestructura:** Docker & Docker Compose.
- **Herramientas Externas (Backend):** - `yt-dlp` (para descargar videos de IG).
  - `ffmpeg` (procesamiento de audio).
- **IA:**
  - Audio-to-Text: OpenAI Whisper API (o Groq/Gemini si soporta audio directo).
  - Text-to-Structure: Google Gemini API (Model: 1.5 Flash).

## 3. Estructura de Datos (Entidad Receta)

- ID (UUID)
- OriginalURL (String)
- LocalVideoPath (String)
- Title (String)
- Transcript (Text - Raw whisper output)
- Ingredients (JSON/Array)
- Steps (JSON/Array)
- Tags (Relational table - Many to Many)
- CreatedAt (DateTime)

## 4. Fases de Desarrollo (Roadmap)

### FASE 1: Backend Core & Infraestructura (Go)

**Objetivo:** Levantar el servidor y lograr descargar un video de IG.

1. Configurar proyecto Go con `Gin`.
2. Crear `Dockerfile` que incluya Go, `ffmpeg` y `yt-dlp` (basado en alpine o debian).
3. Endpoint `POST /process`: Recibe `{url: string}`.
4. Lógica: Ejecutar comando de sistema `yt-dlp` para bajar el video a una carpeta `/downloads`.
5. Respuesta: OK si el video se descarga.

### FASE 2: La Tubería de IA (The Pipeline)

**Objetivo:** Transformar el video en datos estructurados.

1. Cliente API para Google Gemini (Multimodal): Enviar video -> recibir JSON.
   - Prompt: "Actúa como un chef experto. Analiza este video. Extrae: Título, Lista de Ingredientes con cantidades, Pasos numerados y Sugiere 5 etiquetas. Devuelve SOLO JSON válido."
2. Parsear el JSON de Gemini.

### FASE 3: Persistencia (Base de Datos)

**Objetivo:** Guardar los resultados.

1. Configurar SQLite con GORM.
2. Definir modelos `Recipe` y `Tag`.
3. Guardar el resultado del pipeline en la DB.
4. Crear Endpoint `GET /recipes` (Listado con paginación/búsqueda).
5. Crear Endpoint `GET /recipes/:id` (Detalle).
6. Servir archivos estáticos (los videos) desde el backend.

### FASE 4: Aplicación Móvil (Flutter) - Visualización

**Objetivo:** Ver las recetas.

1. Crear proyecto Flutter.
2. Pantalla "Home": Grid/Lista de recetas con buscador.
3. Pantalla "Detalle": Reproductor de video (`video_player` + `chewie`), lista de ingredientes (checkboxes) y pasos.
4. Conexión HTTP con el backend (usar IP local para dev).

### FASE 5: Integración "Compartir" (Flutter)

**Objetivo:** Enviar desde Instagram a la App.

1. Implementar `receive_sharing_intent`.
2. Cuando la app se abre por "Intent", mostrar popup "Procesando receta..." y llamar al backend.
3. Manejo de estados (Cargando, Éxito, Error).

## 5. Instrucciones para el Agente (Antigravity)

- Escribe código limpio y modular.
- Usa inyección de dependencias en Go.
- Maneja los errores de descarga (Instagram a veces bloquea, reintentar).
- En Flutter usa `Riverpod` o `Provider` para el estado.
