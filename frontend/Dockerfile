FROM node:18-alpine AS builder

WORKDIR /app

# Install Flutter dependencies
RUN apk add --no-cache \
    git \
    curl \
    unzip \
    bash

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter && \
    /flutter/bin/flutter config --no-analytics && \
    /flutter/bin/flutter precache

ENV PATH="/flutter/bin:$PATH"

# Copy application files
COPY . .

# Build Flutter web
RUN flutter pub get && \
    flutter build web --release

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install serve to run web application
RUN npm install -g serve

# Copy built application
COPY --from=builder /app/build/web ./build/web

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Start application
CMD ["serve", "-s", "build/web", "-l", "3000"]
