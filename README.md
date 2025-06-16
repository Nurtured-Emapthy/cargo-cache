# Cargo Mirror

A Docker Compose project for mirroring Rust crates using Nginx with Let's Encrypt SSL certificates.

## Overview

This project creates a mirror for Rust crates that can be used as an alternative registry for Cargo. It uses:

- Nginx as a reverse proxy and cache server
- Let's Encrypt for SSL certificates
- A custom entrypoint script to dynamically configure the server based on domain name

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/Nurtured-Emapthy/cargo-mirror.git
   cd cargo-mirror
   ```

2. Configure settings in the `.env` file:
   ```
   DOMAIN_NAME=your-domain.example.com
   EMAIL=your-email@example.com
   CACHE_MAX_SIZE=10g
   ```

3. Start the services:
   ```
   docker-compose up -d
   ```

   The certbot service will automatically obtain SSL certificates for your domain.

## Usage

To use this mirror in your Rust projects, add the following to your `.cargo/config.toml` file:

```toml
[source.crates-io]
replace-with = "mirror"

[source.mirror]
registry = "https://your-domain.example.com/api/v1/crates"
```

## Project Structure

- `docker-compose.yml` - Main Docker Compose configuration
- `.env` - Environment variables for domain configuration
- `nginx/` - Nginx configuration
  - `conf.d/` - Directory for Nginx configuration files
  - `templates/` - Template files for Nginx configuration
  - `docker-entrypoint.sh` - Custom Nginx entrypoint script that dynamically generates configuration
- `volumes/` - Persistent data storage
  - `crates/` - Directory for cached crate files
  - `certs/` - Let's Encrypt certificates
  - `certbot_www/` - ACME challenge files for certificate validation

## How It Works

1. The `.env` file defines the domain name and email to use for the mirror and certificates
2. The nginx service uses templates to generate configuration based on the domain name
3. The certbot service automatically obtains and renews Let's Encrypt certificates
4. Nginx serves cached crate files and proxies requests to crates.io when files aren't cached

## Caching Behavior

The mirror implements a two-tier caching strategy. API metadata from `/api/v1/crates` is cached for 1 day to ensure consistent package listings, while actual crate files under `/crates` are cached according to crates.io's cache headers for optimal freshness. If crates.io becomes temporarily unavailable, the mirror will serve stale cache to maintain availability. All cached files are stored in the `volumes/crates/` directory. The maximum cache size can be configured using the `CACHE_MAX_SIZE` variable in the `.env` file (default: 10g).

## Maintenance

- Certificates will automatically renew every 12 hours if needed
- Cached crates are stored in the `volumes/crates/` directory
- Nginx is configured to proxy and cache requests to crates.io

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.