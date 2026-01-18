# Xgastroteca 🍳🤖

**Xgastroteca** es tu recetario personal inteligente. Una plataforma diseñada para capturar, procesar y organizar recetas de cocina a partir de videos de Instagram (Reels), transformando contenido multimedia efímero en una biblioteca estructurada y buscable de sabiduría culinaria.

Utiliza Inteligencia Artificial avanzada (Google Gemini & OpenAI Whisper) para "ver" y "escuchar" los videos, extrayendo automáticamente ingredientes, pasos de preparación y etiquetas, eliminando la necesidad de transcripción manual.

---

## ✨ Características Principales

- **� Captura Inteligente**: Simplemente comparte un enlace de Instagram (o usa el menú "Compartir" de Android) y Xgastroteca descargará el video.
- **🧠 Procesamiento IA (Pipeline)**:
  - **Descarga**: `yt-dlp` obtiene el video en alta calidad.
  - **Transcripción**: Extrae el audio y lo convierte a texto usando modelos de Speech-to-Text (Whisper).
  - **Estructuración**: Google Gemini 1.5 Flash analiza el video y la transcripción para generar un JSON estructurado con título, ingredientes, pasos y tags.
- **📱 Multiplataforma**:
  - **Móvil (Android)**: App nativa Flutter optimizada para uso en cocina.
  - **Web**: Acceso completo desde cualquier navegador de escritorio.
- **📺 Reproductor Integrado**: Visualiza el video original (`chewie`) mientras sigues los pasos de la receta.
- **🏷️ Organización Automática**: Etiquetado inteligente sugerido por la IA para facilitar la búsqueda.

---

## 🛠️ Arquitectura y Tecnologías

El sistema sigue una arquitectura cliente-servidor containerizada.

### Backend (Golang)

El cerebro de la operación, enfocado en rendimiento y concurrencia.

- **Lenguaje**: Go (Golang) 1.24.
- **Framework Web**: [Gin Gonic](https://gin-gonic.com/) - API RESTful rápida y minimalista.
- **Base de Datos**: SQLite con [GORM](https://gorm.io/) - Persistencia ligera y portable (ideal para uso personal).
- **Herramientas CLI**:
  - `yt-dlp`: Descarga de videos de Instagram.
  - `ffmpeg`: Procesamiento de audio y video.
- **IA & Integraciones**:
  - `google/generative-ai-go`: Cliente oficial para Gemini API.

### Frontend (Flutter)

Una única base de código para Móvil y Web.

- **Framework**: Flutter (Dart).
- **Gestión de Estado**: [Riverpod](https://riverpod.dev/) con Code Generation (`riverpod_generator`).
- **Navegación**: `go_router`.
- **Networking**: `dio`.
- **Integración Nativa**: `receive_sharing_intent` para recibir URLs directamente desde la app de Instagram.
- **Reproducción**: `video_player` y `chewie`.

### Infraestructura (DevOps)

- **Docker & Docker Compose**: Orquestación de servicios (Backend + Frontend Web).
- **Proxy Inverso**: [Traefik](https://traefik.io/) maneja el enrutamiento, balanceo de carga y certificados SSL automáticos (Let's Encrypt).
- **Servidor**: Optimizado para Ubuntu Server.

---

## 🚀 Despliegue

Xgastroteca incluye un script automatizado `deploy.sh` que maneja todo el ciclo de vida del despliegue en un servidor remoto.

### Prerrequisitos del Servidor

1.  **Docker** y **Docker Compose** instalados.
2.  Acceso SSH configurado (llave pública añadida).
3.  Carpeta de destino creada (o permisos para crearla).
4.  Dominio apuntando a la IP del servidor.

### Script de Despliegue (`deploy.sh`)

Este script realiza las siguientes tareas:

1.  🏗️ **Compila** la app Android (`flutter build apk`).
2.  🌐 **Compila** la app Web (`flutter build web`).
3.  📂 **Prepara** directorios remotos vía SSH.
4.  🔄 **Sincroniza** (Rsync) el código backend, los binarios compilados y configuraciones, excluyendo archivos basura.
5.  🔐 **Transfiere** el archivo `.env` de producción.
6.  🐳 **Reinicia** los contenedores Docker en el servidor remoto eliminando caché.

**Ejecución:**

```bash
./deploy.sh
```

### Variables de Entorno (.env)

El backend requiere un archivo `.env` en `backend/.env` con las siguientes claves:

```env
# Puerto del servidor (interno del contenedor)
PORT=8080

# Clave API de Google Gemini (AI Studio)
GEMINI_API_KEY=tu_clave_api_aqui

# Configuración de base de datos (opcional si se usa default)
DB_PATH=./data/xgastroteca.db
```

---

## 💻 Instalación y Desarrollo Local

### Requisitos

- [Go](https://go.dev/) 1.24+
- [Flutter SDK](https://flutter.dev/) 3.10+
- [Docker](https://www.docker.com/) (opcional para correr DB o entorno completo)
- `yt-dlp` y `ffmpeg` instalados en el sistema (para correr backend nativo).

### 1. Backend

```bash
cd backend
go mod download
# Crear carpeta data si no existe
mkdir -p data
# Ejecutar
go run main.go
```

El servidor iniciará en `http://localhost:8080`.

### 2. Frontend (Móvil)

Asegúrate de tener un emulador Android o dispositivo conectado.

```bash
cd mobile
# Instalar dependencias
flutter pub get
# Correr generador de código (Riverpod)
dart run build_runner build -d
# Ejecutar app
flutter run
```

### 3. Frontend (Web)

```bash
cd mobile
flutter run -d chrome
```

---

## 📂 Estructura del Proyecto

```
/
├── backend/                # Código fuente del API Server (Go)
│   ├── main.go             # Punto de entrada
│   ├── models/             # Esquemas de GORM (Recipe, Tag)
│   ├── services/           # Lógica de negocio (Pipeline de IA, Downloader)
│   ├── utils/              # Funciones auxiliares
│   ├── Dockerfile.prod     # Imagen de producción para Backend
│   └── go.mod              # Dependencias de Go
│
├── mobile/                 # Aplicación Flutter (Web & App)
│   ├── lib/
│   │   ├── main.dart       # Punto de entrada
│   │   ├── core/           # Configuración, rutas, tema
│   │   ├── features/       # Módulos (Home, Details, Share)
│   │   └── shared/         # Widgets reutilizables
│   ├── android/            # Configuración nativa Android
│   ├── web/                # Configuración Web
│   ├── Dockerfile.web      # Imagen Nginx para servir Flutter Web
│   └── pubspec.yaml        # Dependencias de Flutter
│
├── data/                   # Volúmen persistente (SQLite + Videos descargados)
├── deploy.sh               # Script maestro de despliegue
└── docker-compose.prod.yml # Definición de servicios para producción
```

---

## 🤝 Contribución

Este es un proyecto personal, pero las sugerencias son bienvenidas.

1.  Haz un Fork.
2.  Crea tu rama (`git checkout -b feature/AmazingFeature`).
3.  Commit tus cambios (`git commit -m 'Add some AmazingFeature'`).
4.  Push a la rama (`git push origin feature/AmazingFeature`).
5.  Abre un Pull Request.

---

**Creado con ❤️ y demasiada cafeína por Antonio Tirado.**
