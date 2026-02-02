# Simple, production-grade static hosting via Nginx
FROM nginx:alpine

# Remove default nginx landing page and add ours
RUN rm -rf /usr/share/nginx/html/*

# Copy our premium HTML
COPY index.html /usr/share/nginx/html/index.html

# Healthcheck (optional but nice)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

# Expose port for documentation (K8s service handles real exposure)
EXPOSE 80
