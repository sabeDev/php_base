# Custom PHP 8.3 Apache Base Image

A production-ready Docker base image built on Debian Bookworm with Apache and PHP 8.3. It includes pre-configured database drivers for Oracle, Microsoft SQL Server, and MySQL, alongside commonly needed enterprise PHP extensions and debugging tools.

---

## Features & Included Components

### Base Environment
* **Base Image**: `php:8.3-apache-bookworm`
* **Web Server**: Apache 2.4 with `mod_rewrite` enabled
* **Work Directory**: `/var/www/html`
* **Exposed Port**: `80`
* **Target Architecture**: `linux/amd64` (required for Oracle Instant Client and Microsoft ODBC packages)

### Database Drivers & Clients
* **Oracle Database**:
  * Oracle Instant Client v19.18 (Basic Lite + SDK)
  * PHP extension: `oci8`
  * Environment: `ORACLE_HOME` and `LD_LIBRARY_PATH` configured to `/opt/oracle/instantclient`
* **Microsoft SQL Server**:
  * Microsoft ODBC Driver 18 for SQL Server (`msodbcsql18`, `mssql-tools18`)
  * PHP extensions: `sqlsrv`, `pdo_sqlsrv`
* **MySQL**:
  * PHP extension: `pdo_mysql`

### Additional PHP Extensions
* **GD**: Configured with FreeType and JPEG support (`--with-freetype --with-jpeg`)
* **LDAP**: Multi-arch library path auto-detection
* **SOAP**: Full SOAP client/server support
* **OPcache**: Pre-tuned for performance
* **Xdebug**: Pre-installed and ready for containerized remote debugging

---

## PHP Configuration Defaults

Custom settings applied via `/usr/local/etc/php/conf.d/custom.ini`:

| Directive | Default Value | Notes |
| :--- | :--- | :--- |
| `date.timezone` | `Europe/Brussels` | Localized default timezone |
| `max_execution_time` | `120` | Script timeout in seconds |
| `default_socket_timeout` | `120` | Connection timeout in seconds |
| `memory_limit` | `128M` | Maximum memory allocated per script |
| `opcache.enable` | `1` | Bytecode caching enabled |
| `opcache.validate_timestamps` | `1` | Re-checks file modifications |
| `opcache.revalidate_freq` | `2` | Check interval in seconds |

---

## Xdebug Configuration

Configured via `/usr/local/etc/php/conf.d/xdebug.ini`:

```ini
xdebug.mode=debug
xdebug.start_with_request=trigger
xdebug.client_host=host.containers.internal
xdebug.client_port=9003
xdebug.log_level=0
```

* **Trigger Mode**: Xdebug will only initiate a debugging session when triggered (e.g., via browser extension `XDEBUG_SESSION` cookie or query parameter).
* **Docker Host**: Uses `host.containers.internal` (or `host.docker.internal` on Docker Desktop) pointing to port `9003`.
* You can override the mode at container runtime by passing the `XDEBUG_MODE` environment variable (e.g., `-e XDEBUG_MODE=off` or `-e XDEBUG_MODE=develop,debug`).

---

## Building and Running

### 1. Build the Image
```bash
docker build -t php-base:8.3 .
```

If building on an Apple Silicon or ARM64 host, ensure you target `linux/amd64`:
```bash
docker build --platform linux/amd64 -t php-base:8.3 .
```

### 2. Using as a Base in Downstream Projects
In your application's `Dockerfile`:
```dockerfile
FROM php-base:8.3

# Copy application code
COPY . /var/www/html/
```

### 3. Run a Quick Test Container
```bash
docker run -d --name test-php -p 8080:80 php-base:8.3
```
Verify the container is responding at `http://localhost:8080`.

---

## License

This repository and Dockerfile are provided under the MIT License. Note that vendor libraries (Oracle Instant Client, Microsoft ODBC Driver) are subject to their respective vendor license agreements.
