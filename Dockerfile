FROM nginx:alpine

LABEL org.opencontainers.image.title="workstation-web"
LABEL org.opencontainers.image.description="Static site for the developer workstation assignment"

COPY app/index.html /usr/share/nginx/html/index.html
