FROM php:8.2-cli

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libonig-dev libxml2-dev libzip-dev curl zip gnupg ca-certificates \
    build-essential && \
    docker-php-ext-install pdo_mysql mbstring xml zip gd

# Install composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files first (cache layers)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --no-interaction --no-progress

# Copy project
COPY . .

# Install Node and build assets using system package manager (Node may be present on base image for simplicity)
# If you prefer a specific Node version, replace with Node install steps.
RUN apt-get update && apt-get install -y nodejs npm && \
    npm ci --no-audit --no-fund --silent || true && npm run build --silent || true

# Fix permissions for storage and cache
RUN mkdir -p storage/framework/{sessions,views,cache} && \
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

EXPOSE 10000

# Default command runs the start script (web). The script will switch to worker if "worker" arg is passed.
CMD ["sh", "docker/start.sh"]