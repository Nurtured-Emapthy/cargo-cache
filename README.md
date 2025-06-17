# Cargo Mirror

A Docker Compose project for mirroring Rust crates using Nginx with Let's Encrypt TLS certificates.

## Overview

This project creates a mirror for Rust crates that can be used as an alternative registry for Cargo. It uses a custom entrypoint script to dynamically configure the server based on domain name. You *must* modify the .env file to configure the system and agree to Let's Encrypt's [terms of service](https://community.letsencrypt.org/tos) before it will run.

This project currently requires:
* Full access to ports 80 and 443 on the host because of Let's Encrypt
* A custom domain for this project
* The ability for Let's Encrypt to access this project at the custom domain

If you want to implement your own security, the caching components are all under the [nginx](nginx) folder.

Please be mindful of [the risks](https://en.wikipedia.org/wiki/Supply_chain_attack) of being the supplier or consumer of this software.

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
   TOS=--agree-tos
   ```

3. Start the services and watch for errors:
   ```
   docker-compose up
   ```

   The certbot service will automatically obtain SSL certificates for your domain.

4. Assuming no errors:
   ```
   docker-compose up -d
   ```

## Usage

To use this mirror in your Rust projects, add the following to your `.cargo/config.toml` file either in your user's home folder (globally) or the root of your Rust project or workspace. Remember to modify it to use your domain name.

```toml
[source.crates-io]
replace-with = "mirror"

[source.mirror]
registry = "sparse+https://your-domain.example.com/"
```

## How It Works

1. The `.env` file defines the domain name and email to use for the mirror and certificates
2. The nginx service uses templates to generate configuration based on the domain name
3. The certbot service automatically obtains and renews Let's Encrypt certificates
4. Nginx automatically restarts after a default of 30 seconds to load the new certificate
5. Nginx serves cached crate files and proxies requests to crates.io when files aren't cached

## Caching Behavior

The mirror implements a two-tier caching strategy. API metadata is cached for 1 day to ensure consistent package listings, while actual crate files under `/crates` are cached according to crates.io's cache headers (365 days as of June 2025). If crates.io becomes temporarily unavailable, the mirror will serve stale cache to maintain availability. All cached files are stored in the `volumes/crates/` directory. The maximum cache size can be configured using the `CACHE_MAX_SIZE` variable in the `.env` file.

## Maintenance

- Certificates will automatically renew every 12 hours if needed
- Cached crates are stored in the `volumes/crates/` directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.