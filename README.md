# docker-inception

A Docker-based infrastructure project inspired by the 42 Paris *Inception* subject. Runs a complete multi-service environment using Docker Compose with a custom bridge network and TLS termination.

## Services

| Service | Details |
|---------|---------|
| **Nginx** | TLS reverse proxy (port 443, self-signed certificate) |
| **WordPress** | PHP-FPM managed WordPress instance |
| **MariaDB** | Persistent relational database for WordPress |

## Architecture

```
Client → Nginx (443/TLS) → WordPress (PHP-FPM) → MariaDB
```

All services run in isolated Docker containers on a custom bridge network. Persistent data is stored in named Docker volumes.

## Getting Started

```bash
make        # Build and start all containers
make clean  # Stop and remove containers
make fclean # Full cleanup including images and volumes
```

## Tech Stack

`Docker` `Docker Compose` `Nginx` `WordPress` `MariaDB` `PHP-FPM` `Makefile`
