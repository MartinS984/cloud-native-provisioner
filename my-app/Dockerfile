# Use a lightweight Nginx image as the base
FROM nginx:alpine

# Copy our custom HTML file into the Nginx default hosting directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 for web traffic
EXPOSE 80