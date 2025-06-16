#!/bin/sh
set -e

# Configuration
NGINX_WAIT=10  # Seconds to wait for certbot to use the webroot

# Check if domain name is set
if [ -z "$DOMAIN_NAME" ]; then
    echo "ERROR: DOMAIN_NAME environment variable is not set"
    exit 1
fi

# Check if domain name is still the default example value
if [ "$DOMAIN_NAME" = "crates-mirror.example.com" ]; then
    echo "ERROR: DOMAIN_NAME is still set to the example value. Please change it."
    exit 1
fi

# Process templates
cat /etc/nginx/templates/index.html.template | envsubst '${DOMAIN_NAME}' > /var/www/html/index.html

# Check if SSL certificates exist
if [ -d "/etc/letsencrypt/live/${DOMAIN_NAME}" ]; then
    echo "Using SSL configuration for ${DOMAIN_NAME}"
    cat /etc/nginx/templates/default.conf.template | envsubst '${DOMAIN_NAME} ${CACHE_MAX_SIZE}' > /etc/nginx/conf.d/default.conf
else
    echo "SSL certificates not found. Using HTTP-only configuration until certificates are available."
    cat /etc/nginx/templates/http-only.conf.template | envsubst '${DOMAIN_NAME}' > /etc/nginx/conf.d/default.conf
    
    # Start nginx temporarily to allow certbot to use the webroot
    echo "Starting nginx temporarily to allow certbot to use the webroot"
    nginx &
    
    # Sleep to allow certbot to use the webroot
    echo "Sleeping for ${NGINX_WAIT} seconds to allow certbot to use the webroot"
    sleep ${NGINX_WAIT}
    
    # Exit with an error to trigger container restart
    # This will allow nginx to check for certificates again after certbot creates them
    echo "Exiting to allow container to restart and check for certificates again"
    exit 1
fi

echo "Configuration generated for domain: ${DOMAIN_NAME}"