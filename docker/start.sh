#!/usr/bin/env sh
set -e

# Install PHP dependencies if missing (useful if vendor was not baked into image)
if [ ! -d vendor ]; then
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Install/build Node assets if missing (best-effort)
if [ ! -d node_modules ]; then
  npm ci --silent || true
  npm run build --silent || true
fi

# Run migrations (will fail if DB not ready; don't exit on failure)
php artisan migrate --force || echo "php artisan migrate failed or DB not ready, continuing"

# Cache config/views/routes where useful
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Start worker or web server
if [ "$1" = "worker" ]; then
  exec php artisan queue:work --sleep=3 --tries=3 --daemon
else
  PORT=${PORT:-10000}
  exec php artisan serve --host=0.0.0.0 --port=$PORT
fi