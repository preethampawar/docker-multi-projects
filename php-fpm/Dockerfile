FROM php:8.3-fpm

# system deps + common php extensions for CakePHP2 and Laravel 12
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip libzip-dev libonig-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libxml2-dev libicu-dev default-mysql-client libssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql zip mbstring bcmath xml intl opcache \
    && rm -rf /var/lib/apt/lists/*

# composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Install Node.js and npm for Laravel Vite build support
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

# recommended: create app user with UID matching your host user (optional)
# RUN useradd -u 1000 -m appuser && chown -R appuser:appuser /var/www

EXPOSE 9000
CMD ["php-fpm"]

