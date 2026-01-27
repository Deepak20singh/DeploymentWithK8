# Lightweight Nginx
FROM nginx:alpine

# App metadata
ARG BUILD_VERSION=dev
ENV BUILD_VERSION=${BUILD_VERSION}

# Copy static site
COPY index.html /usr/share/nginx/html/index.html

# Optional: show build in a header for debugging
RUN echo "add_header X-Build-Version ${BUILD_VERSION};" \
    > /etc/nginx/conf.d/build.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
