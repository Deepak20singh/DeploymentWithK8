
FROM nginx:1.25-alpine

# non-root best practice (optional but fine to skip on demo)
# RUN addgroup -S app && adduser -S app -G app

# Copy your static site
COPY ./index.html /usr/share/nginx/html/index.html

# Healthcheck (company style)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://127.0.0.1 || exit 1

EXPOSE 80

# USER app
``
