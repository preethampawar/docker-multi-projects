FROM php:8.3-fpm

# System deps, PHP extensions (CakePHP 2 + Laravel 12), and Node.js 20 for Vite — single layer.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip zip curl ca-certificates gnupg \
        libzip-dev libonig-dev libpng-dev libjpeg-dev libfreetype6-dev \
        libxml2-dev libicu-dev default-mysql-client libssl-dev \
        libmagickwand-dev ghostscript \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd pdo pdo_mysql zip mbstring bcmath xml intl opcache \
    && pecl install imagick && docker-php-ext-enable imagick \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Allow Imagick to process PDF files (Ghostscript policy)
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' /etc/ImageMagick-6/policy.xml 2>/dev/null || true

# composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# recommended: create app user with UID matching your host user (optional)
# RUN useradd -u 1000 -m appuser && chown -R appuser:appuser /var/www

EXPOSE 9000
CMD ["php-fpm"]

