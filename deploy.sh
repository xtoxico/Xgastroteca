#!/bin/bash

# Configuration
REMOTE_USER="xtoxico"
REMOTE_HOST="192.168.2.20"
REMOTE_DIR="~/xgastroteca_deploy"
PROJECT_ROOT=$(pwd)

echo "🚀 Iniciando despliegue de Xgastroteca..."

# 1. Compilar Flutter Mobile (APK)
echo "📦 Construyendo APK..."
cd mobile
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "❌ Error construyendo APK"
    exit 1
fi

# 2. Compilar Flutter Web
echo "🌐 Construyendo Web..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "❌ Error construyendo Web"
    exit 1
fi
cd ..

# 3. Preparar directorio remoto
echo "📂 Preparando servidor remoto ($REMOTE_HOST)..."
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR/backend $REMOTE_DIR/mobile/build/web $REMOTE_DIR/mobile/build/app/outputs/flutter-apk $REMOTE_DIR/data"

# 4. Sincronizar archivos (Rsync)
# Excluyendo node_modules, .git, builds innecesarios, etc.
echo "🔄 Sincronizando archivos..."

# Backend (Source + Dockerfile)
rsync -avz --delete \
    --exclude 'data' \
    --exclude '.git' \
    --exclude 'tmp' \
    --exclude 'tests' \
    ./backend/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/backend/

# Mobile (Web Build + APK + Dockerfile + Nginx Config)
# Sync Web Build
rsync -avz --delete ./mobile/build/web/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/mobile/build/web/
# Sync APK
rsync -avz ./mobile/build/app/outputs/flutter-apk/app-release.apk $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/mobile/build/app/outputs/flutter-apk/
# Sync Configs
rsync -avz ./mobile/Dockerfile.web $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/mobile/
rsync -avz ./mobile/nginx.conf $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/mobile/

# Docker Compose
rsync -avz ./docker-compose.prod.yml $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/docker-compose.yml

# Sync .env
if [ -f ./backend/.env ]; then
    echo "🔑 Sincronizando .env..."
    rsync -avz ./backend/.env $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/.env
else
    echo "⚠️  No se encontró ./backend/.env localmente."
fi

# 5. Desplegar en Remoto
echo "🐳 Desplegando Docker en remoto..."
ssh $REMOTE_USER@$REMOTE_HOST << EOF
    cd $REMOTE_DIR
    
    # Check for .env file
    if [ ! -f .env ]; then
        echo "⚠️  ADVERTENCIA: No se encontró archivo .env en remoto."
        echo "    Por favor crea $REMOTE_DIR/.env con GEMINI_API_KEY=..."
    fi

    # Build and Up
    echo "    Reconstruyendo contenedores..."
    # Try 'docker compose' (v2) first, fall back to 'docker-compose' (v1) if needed, but v2 is standard on 24.04
    if command -v docker-compose &> /dev/null; then
        docker-compose down
        docker-compose -f docker-compose.yml up -d --build
    else
        docker compose down
        docker compose -f docker-compose.yml up -d --build
    fi
EOF

echo "✅ Despliegue completado con éxito!"
echo "✅ Backend API: https://api-xgastroteca.antoniotirado.com"
echo "✅ Frontend Web: https://xgastroteca.antoniotirado.com"
