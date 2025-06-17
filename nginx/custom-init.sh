#!/bin/sh
set -e

if [ -z "$DOMAIN_NAME" ]; then
    echo "ERROR: DOMAIN_NAME environment variable is not set"
    exit 1
fi

if [ "$DOMAIN_NAME" = "crates-mirror.example.com" ]; then
    echo "ERROR: DOMAIN_NAME is still set to the example value."
    echo "Please change it to allow certbot to generate a valid certificate."
    exit 1
fi

# Process templates
cat /etc/nginx/templates/cargo-config.json.template | envsubst > /var/www/config.json

# Load different configs whether or not there's a certificate
if [ -d "/etc/letsencrypt/live/${DOMAIN_NAME}" ]; then
    echo "Using SSL configuration for ${DOMAIN_NAME}"
    cat /etc/nginx/templates/default.conf.template | envsubst > /etc/nginx/conf.d/default.conf
else
    echo "SSL certificates not found. Using HTTP-only configuration until certificates are available."
    cat /etc/nginx/templates/http-only.conf.template | envsubst > /etc/nginx/conf.d/default.conf

    nginx &
    
    echo "Waiting for ${NGINX_WAIT} seconds to allow certbot to use the webroot"
    sleep ${NGINX_WAIT}
    
    echo "Exiting to allow container to restart and check for certificates again"
    exit 1
fi
