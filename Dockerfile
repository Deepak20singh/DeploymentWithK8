
# Small, production-grade base
FROM nginx:alpine

# Remove default page and add our index.html
RUN rm -rf /usr/share/nginx/html/*
COPY index.html /usr/share/nginx/html/index.html

# Expose port (K8s service will map)
EXPOSE 80

# Nginx default CMD works
