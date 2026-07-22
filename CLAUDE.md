# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **infrastructure only** — a Docker Compose harness that runs multiple PHP web applications side-by-side on a single developer machine. The application source code lives **outside this repo**, under `~/php-projects/` (the host path `/Users/preetham/php-projects/`). This repo contains the orchestration: `docker-compose.yml`, the shared PHP-FPM image, per-app nginx vhosts, DB init scripts, and a `Makefile` that wraps the common workflows.

When asked to change "an app", clarify whether the change belongs in this infra repo (nginx vhost, PHP extension, DB user, container wiring) or in the app's own repo under `~/php-projects/`.

## Architecture

One shared `mysql8` container, one shared `nginx` container, one **PHP-FPM container per app** (all built from the same `php-fpm/Dockerfile`). Nginx routes by `server_name` to the appropriate `php_*:9000` upstream. App source directories are bind-mounted into both the relevant PHP-FPM container (read-write) and the nginx container (read-only) at matching paths like `/var/www/<app>`.

Adding a new app means coordinated edits across **four** places:
1. New `php_<app>` service in `docker-compose.yml` with the host bind-mount.
2. Same host directory added as a read-only mount on the `nginx` service, plus the new `php_<app>` added to `nginx.depends_on`.
3. New vhost file in `nginx/conf.d/<app>.conf` with `fastcgi_pass php_<app>:9000` and `root` matching the in-container mount path.
4. Optional: new DB + user grant in `db-init/01-create-dbs.sql` (note: that script only runs on a **fresh** `db_data` volume — for an existing setup, create the DB/user manually via Adminer or `mysql`).

A staging variant of `liq` is currently commented out in both `docker-compose.yml` (`php_liq_staging`) and exists as `nginx/conf.d/winesapp_staging.conf` — keep them consistent if re-enabling.

### Apps currently wired up

| Nginx vhost | PHP container | Host source | Framework |
|---|---|---|---|
| `pnursery-base.conf` | `php_pnursery_base` | `~/php-projects/pnursery-base` | CakePHP |
| `pnursery-clients.conf` | `php_pnursery_clients` | `~/php-projects/pnursery-clients` | CakePHP |
| `winesapp.conf` | `php_liq` | `~/php-projects/liq-webapp-cakephp210-php8` | CakePHP 2.10 |
| `winesapp_v1.conf` | `php_liq_v1` | `~/php-projects/liq-webapp-cakephp210-php8-v1` | CakePHP 2.10 |
| `winesapp_v1_mobile.conf` | `php_liq_v1_mobile` | `~/php-projects/liq-mobile-responsive-cakephp210-php8` | CakePHP 2.10 |
| `gramavani.conf` | `php_news` | `~/php-projects/news-portal` | Laravel |

The `*.lc` hostnames in vhosts (e.g. `winesapp.lc`) require corresponding `/etc/hosts` entries on the developer machine pointing at `127.0.0.1`.

### PHP-FPM image

`php-fpm/Dockerfile` is shared by every `php_*` service. It's PHP 8.3-fpm with the extensions needed by both CakePHP 2.10 and Laravel 12 (`gd`, `pdo_mysql`, `zip`, `mbstring`, `bcmath`, `xml`, `intl`, `opcache`, `imagick` with PDF policy unlocked), plus Composer 2.6 and Node.js 20 for Laravel Vite builds. Changing it rebuilds **every** app container — `make up`/`make restart` both pass `--build`.

## Common commands

All workflows go through the `Makefile`. Run `make help` for the full menu; the most-used:

- `make up` — build and start everything; on first boot also runs `composer install`, `npm install`, `artisan optimize:clear`, and `artisan migrate --force` inside `php_news` (Laravel). The composer/npm steps are guarded by directory existence checks, so they're idempotent on subsequent ups.
- `make restart` — full rebuild + unconditional Laravel reinit (composer, npm, cache clear, migrate). Heavier than `make up` — use when the PHP image or Laravel deps have changed.
- `make down` / `make logs`
- `make bash-<app>` — shell into a PHP container (`bash-pnursery-base`, `bash-pnursery-clients`, `bash-liq`, `bash-liq-v1`, `bash-liq-v1-mobile`, `bash-news`).
- `make test-nginx-config` — runs `nginx -t` inside the nginx container; use after editing any `nginx/conf.d/*.conf`.
- Laravel-only (targets `php_news`/`gramavani`): `make laravel-key`, `make laravel-cache`, `make laravel-migrate`, `make laravel-seed`, `make laravel-build`, `make laravel-watch`, `make composer-install`, `make npm-install`. There are no equivalent shortcuts for the CakePHP apps — work in those via `make bash-<app>`.

### Database import/backup

- `make import dump=<file>` — accepts `.sql`, `.sql.gz`, or `.sql.zip`; auto-detects by extension and pipes into `mysql8`.
- `make backup db=<dbname>` — single DB → `~/php-projects/db-dumps/<db>_backup_<ts>.sql.gz`.
- `make backup-all` — `mysqldump --all-databases --single-transaction` → same dir.

Seed dumps for fresh setups live in `db-setup/` (`news_portal.sql.gz`, `pnursery.sql.gz`, `winesapp_v1.sql.gz`, `winesapp_v3.sql.gz`); import them with `make import dump=db-setup/<file>`.

## Service endpoints

- MySQL: `localhost:3306` (root password from `.env`; app users `spr_user`/`liq_user`/`news_user` with `*_pass`, all granted `*.*`)
- Adminer: `http://localhost:8081`
- MailHog: SMTP on `1025`, web UI on `http://localhost:8025` — apps should send mail to `mailhog:1025` over the `backend` network
- Nginx: `80`/`443`

## Networking

Two Docker networks: `frontend` (nginx only) and `backend` (everything else, including nginx). Inter-container DNS uses the service/container name — e.g. nginx vhosts reach PHP via `php_<app>:9000`, and apps reach the DB at host `mysql` (service name) or `mysql8` (container name).
