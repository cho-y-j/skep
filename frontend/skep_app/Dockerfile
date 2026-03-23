FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy the entire project
COPY . .

# Get dependencies
RUN flutter pub get

# Build web application
RUN flutter build web --release

# Use nginx as the final image
FROM nginx:alpine

# Copy the built web app to nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
