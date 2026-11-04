# ==========================================
# STAGE 1: build de Flutter Web
# ==========================================
# Esto SOLO compila la versión web. No afecta ni reemplaza los builds
# de Android/iOS: esos se siguen haciendo con "flutter build apk" /
# "flutter build ios" en tu máquina, desde el mismo código.
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Por defecto ApiConfig.baseUrl ya apunta a http://127.0.0.1:8000, que
# es donde el backend queda publicado en el host (docker-compose.yml).
# Si vas a desplegar en otra máquina, sobreescribe con:
#   docker compose build frontend --build-arg API_BASE_URL=http://mi-servidor:8000
# --pwa-strategy=none desactiva el service worker de Flutter Web. Sin
# esto, el navegador cachea agresivamente el build anterior y los
# cambios nuevos no se ven reflejados aunque reconstruyas la imagen
# (hay que desregistrar el service worker a mano cada vez). Para un
# contenedor de desarrollo/pruebas no necesitas soporte offline/PWA,
# así que se apaga de raíz.
ARG API_BASE_URL=http://127.0.0.1:8000
RUN flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=${API_BASE_URL}

# ==========================================
# STAGE 2: servir los archivos estáticos con nginx
# ==========================================
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
