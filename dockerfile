# Stage 1: Build the Laravel application and install Composer dependencies
FROM composer:2 AS builder

WORKDIR /app

# Copy the composer files
COPY composer.json composer.lock ./

# Install composer dependencies
RUN composer install --ignore-platform-reqs --no-scripts --no-autoloader

# Copy the rest of the application files
COPY . .

# Generate the composer autoload files and optimize
RUN composer dump-autoload --optimize

# Build the Laravel application
RUN php artisan optimize:clear
RUN php artisan config:cache
RUN php artisan route:cache

# Stage 2: Set up the final image with Apache, PHP, Node.js, and npm
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    curl

# Enable required Apache modules
RUN a2enmod rewrite

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs npm

# Install frontend dependencies using npm
WORKDIR /var/www/html
COPY package*.json ./
RUN npm install

# Generate the optimized frontend assets
#RUN npm run build

# Copy the Laravel application from the builder stage
COPY --from=builder /app /var/www/html

# Set the proper ownership and permissions
#RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Set up the Apache virtual host
COPY docker/apache/000-default.conf  /etc/apache2/sites-available/000-default.conf

# Enable Apache site
RUN a2ensite 000-default

# Expose port 80
EXPOSE 80

# Start the Apache server
CMD ["apache2-foreground"]
