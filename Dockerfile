# Use the official PHP 8.2 image as the base image
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    && docker-php-ext-install pdo_mysql zip

# Enable Apache rewrite module
RUN a2enmod rewrite

# Set the working directory in the container
WORKDIR /var/www/html

# Copy the composer.lock and composer.json files to install dependencies separately
COPY composer.lock composer.json ./

# Install composer dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install --no-scripts --no-autoloader

# Copy the rest of the application code
COPY . .

# Set permissions for Laravel storage and bootstrap cache folders
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# Generate the optimized autoload files
RUN composer dump-autoload --optimize

# Set up the Apache virtual host configuration
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable PHP error logging
RUN mkdir -p /usr/local/etc/php/conf.d \
    && echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-php-error-log.ini \
    && echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/docker-php-error-log.ini

# Expose port 80
EXPOSE 80

# Start the Apache server
CMD ["apache2-foreground"]
