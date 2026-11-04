# ==========================================
# Landing page de Raccord — HTML/CSS/JS plano, sin build.
# ==========================================
# Deliberadamente NO es React/Vite ni Flutter: es una página de
# marketing (SEO + tiempo de carga importan más que consistencia de
# stack), así que un solo stage de nginx sirviendo estático alcanza —
# sin node_modules, sin bundler, sin superficie de dependencias que
# mantener/parchear.
FROM nginx:alpine

# URL del backend (raccord_backend) contra la que pega el formulario de
# contacto (POST /contact, ver app/routes/contact_routes.py). Al no
# haber bundler que lea variables de entorno en runtime, se sustituye
# el token __API_BASE_URL__ del HTML en build time con sed — mismo
# propósito que --dart-define=API_BASE_URL en raccord_flutter/Dockerfile,
# adaptado a HTML plano.
#   docker compose build landing --build-arg API_BASE_URL=https://api.tu-dominio.com
ARG API_BASE_URL=http://127.0.0.1:8000

# URL de la app (raccord_flutter) a la que apunta el botón "Ingresar"
# del navbar (-> /login). En local es el puerto donde queda publicado
# el contenedor "frontend" (ver docker-compose.yml); al desplegar en un
# dominio real, cambiar por ej. a https://app.tu-dominio.com.
#   docker compose build landing --build-arg APP_URL=https://app.tu-dominio.com
ARG APP_URL=http://localhost:8081

# Main.html pasa a ser el index.html servido por nginx; el nombre del
# archivo fuente en el repo no se toca. assets/ trae los logos (antes
# la página cargaba tres logos desde un raw.githubusercontent.com de un
# repo privado, que devolvía 404 — ahora quedan empaquetados en la
# misma imagen, sin depender de una URL externa).
COPY "Main.html" /usr/share/nginx/html/index.html
COPY Styles.css /usr/share/nginx/html/Styles.css
COPY assets/ /usr/share/nginx/html/assets/
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN sed -i \
    -e "s|__API_BASE_URL__|${API_BASE_URL}|g" \
    -e "s|__APP_URL__|${APP_URL}|g" \
    /usr/share/nginx/html/index.html

EXPOSE 80
