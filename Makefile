# ============================================================
# DOCKER MULTI-PROJECT MANAGEMENT MAKEFILE
# Author: Preetham Pawar
# ============================================================

# --- Variables ---
PROJECT_ROOT := /Users/preetham/php-projects
DUMP_DIR := $(PROJECT_ROOT)/db-dumps
MDB := mysql8   # container name for mysql

.PHONY: help up down restart logs status wait-mysql bash-pnursery-base bash-pnursery-clients bash-liq bash-liq-v1 bash-liq-v1-mobile bash-news import backup backup-all test-nginx-config laravel-key laravel-cache laravel-migrate laravel-seed laravel-build laravel-watch npm-install composer-install

# ============================================================
# 🧭 HELP MENU
# ============================================================
help:
	@echo ""
	@echo "🚀  VISHO Multi-App Docker Environment"
	@echo "==============================================="
	@echo ""
	@echo "Usage: make [target] [options]"
	@echo ""
	@echo "🧱 Docker Compose Commands"
	@echo "-----------------------------------------------"
	@echo "  make up               🔹 Build and start all containers (then prints status)"
	@echo "  make down             🔹 Stop and remove containers"
	@echo "  make logs             🔹 View live logs from all containers"
	@echo "  make restart          🔹 Restart all containers and reinitialize Laravel app"
	@echo "  make status           🔹 Show all running services with URLs and DB credentials"
	@echo ""
	@echo "🐚 Container Shell Access"
	@echo "-----------------------------------------------"
	@echo "  make bash-pnursery-base    🧩 Access shell of CakePHP app (pnursery-base, main branch)"
	@echo "  make bash-pnursery-clients 🧩 Access shell of CakePHP app (pnursery-clients, main branch)"
	@echo "  make bash-liq         🧩 Access shell of CakePHP app (winesapp, main branch)"
	@echo "  make bash-liq-v1      🧩 Access shell of CakePHP app (winesapp-v1, main_v1 branch)"
	@echo "  make bash-liq-v1-mobile    🧩 Access shell of CakePHP app (closingstock.winesapp-v1, main branch)"
	@echo "  make bash-news        🧩 Access shell of Laravel app (news-portal)"
	@echo ""
	@echo "🔍 NGINX Commands"
	@echo "-----------------------------------------------"
	@echo "  make test-nginx-config  🔎 Test NGINX configuration syntax"
	@echo "	  Expected output:"
	@echo "	  nginx: the configuration file /etc/nginx/nginx.conf syntax is ok"
	@echo "	  nginx: configuration file /etc/nginx/nginx.conf test is successful"
	@echo ""
	@echo "🧱 Laravel Commands (news-portal)"
	@echo "-----------------------------------------------"
	@echo "  make laravel-key        🔐 Generate Laravel application key"
	@echo "  make laravel-cache      🧹 Clear Laravel cache"
	@echo "  make laravel-migrate    🚚 Run Laravel migrations"
	@echo "  make laravel-seed       🌱 Seed the database with initial data"
	@echo "  make composer-install   📦 Install PHP dependencies via Composer"
	@echo "  make npm-install        📦 Install Node.js dependencies via NPM"
	@echo "  make laravel-build      🛠️  Build frontend assets for production"
	@echo "  make laravel-watch      👀 Watch frontend assets for changes"
	@echo ""
	@echo "🗂️  Database Operations"
	@echo "-----------------------------------------------"
	@echo "  make import dump=<file>   💾 Import SQL, .gz, or .zip dump into mysql"
	@echo "      Example: make import dump=$(DUMP_DIR)/zesssta-localhost-dump.sql.zip"
	@echo ""
	@echo "  make backup db=<dbname>   📦 Backup a single database to $(DUMP_DIR)"
	@echo "      Example: make backup db=sprphysio_db"
	@echo ""
	@echo "  make backup-all           📦 Backup all databases (compressed .sql.gz)"
	@echo ""
	@echo "🧹 Housekeeping"
	@echo "-----------------------------------------------"
	@echo "  docker ps                🔸 List running containers"
	@echo "  docker exec -it mysql8 bash 🔸 Manual shell access to mysql"
	@echo ""
	@echo "==============================================="
	@echo "Tip: Run 'make help' anytime to see this menu."
	@echo ""

# ============================================================
# 🐳 DOCKER SERVICE COMMANDS
# ============================================================
up:
	docker-compose up -d --build
	@$(MAKE) -s wait-mysql
	@echo "Installing Laravel dependencies (Composer + npm)..."
	docker exec -i php_news bash -c "cd /var/www/gramavani && if [ ! -d vendor ]; then composer install; fi"
	docker exec -i php_news bash -c "cd /var/www/gramavani && if [ ! -d node_modules ]; then npm install; fi"
	docker exec -i php_news bash -c "cd /var/www/gramavani && php artisan optimize:clear"
	docker exec -i php_news bash -c "cd /var/www/gramavani && php artisan migrate --force"
	@$(MAKE) -s status

down:
	docker-compose down

# Restart: stop, rebuild, and reinitialize Laravel (idempotent: skips composer/npm if already installed)
restart:
	@echo "Stopping and removing existing containers..."
	docker-compose down
	@echo "Rebuilding and restarting containers..."
	docker-compose up -d --build
	@$(MAKE) -s wait-mysql
	@echo "Installing Laravel dependencies (only if missing)..."
	docker exec -i php_news bash -c "cd /var/www/gramavani && if [ ! -d vendor ]; then composer install; fi"
	docker exec -i php_news bash -c "cd /var/www/gramavani && if [ ! -d node_modules ]; then npm install; fi"
	@echo "Clearing Laravel caches..."
	docker exec -i php_news bash -c "cd /var/www/gramavani && php artisan optimize:clear"
	@echo "Running database migrations..."
	docker exec -i php_news bash -c "cd /var/www/gramavani && php artisan migrate --force"
	@$(MAKE) -s status

# Wait for MySQL to report healthy (uses the healthcheck defined in docker-compose.yml)
wait-mysql:
	@printf "⏳ Waiting for MySQL to become healthy"
	@i=0; until [ "$$(docker inspect -f '{{.State.Health.Status}}' $(MDB) 2>/dev/null)" = "healthy" ]; do \
		i=$$((i+1)); \
		if [ $$i -ge 60 ]; then echo " ❌ timed out after 60s"; exit 1; fi; \
		printf "."; sleep 1; \
	done
	@echo " ✅"

# Show live logs from all containers
logs:
	docker-compose logs -f

# ============================================================
# 📋 SERVICE STATUS — URLs and credentials
# ============================================================
status:
	@echo ""
	@echo "==============================================="
	@echo "🚀  Multi-App Docker Environment — running"
	@echo "==============================================="
	@echo ""
	@echo "📦  Containers:"
	@docker ps --filter "label=com.docker.compose.project" --format "  {{.Names}}\t{{.Status}}" | sort
	@echo ""
	@echo "🌐  Web apps  (add *.lc hostnames to /etc/hosts → 127.0.0.1)"
	@echo "  pnursery-base       http://pnursery.lc"
	@echo "  pnursery-clients    http://safinursery.pnursery.lc  http://greengrowersnursery.pnursery.lc"
	@echo "                      http://saibaba.pnursery.lc      http://sprphysio.lc"
	@echo "  winesapp (main)     http://winesapp.lc"
	@echo "  winesapp v1         http://winesapp_v1.lc"
	@echo "  winesapp v1 mobile  http://closingstock.winesapp_v1.lc"
	@echo "  gramavani (Laravel) http://gramavani.lc"
	@echo ""
	@echo "🛠️  Admin / dev tools"
	@echo "  Adminer             http://localhost:8081  (server: mysql, user: root, pass: see .env)"
	@echo "  MailHog UI          http://localhost:8025  (SMTP: mailhog:1025)"
	@echo ""
	@echo "🗄️  MySQL  (host: localhost:3306 from host, mysql:3306 from containers)"
	@echo "  root      / root        (MYSQL_ROOT_PASSWORD in .env)"
	@echo "  spr_user  / spr_pass    (pnursery apps)"
	@echo "  liq_user  / liq_pass    (winesapp main / v1 / mobile)"
	@echo "  news_user / news_pass   (gramavani / Laravel)"
	@echo ""

# ============================================================
# 🐚 CONTAINER SHELL ACCESS
# ============================================================
bash-pnursery-base:
	docker exec -it php_pnursery_base bash

bash-pnursery-clients:
	docker exec -it php_pnursery_clients bash

bash-liq:
	docker exec -it php_liq bash

bash-liq-v1:
	docker exec -it php_liq_v1 bash

bash-liq-v1-mobile:
	docker exec -it php_liq_v1_mobile bash

bash-news:
	docker exec -it php_news bash

# ============================================================
# 🔍 NGINX CONFIG TEST
# ============================================================
test-nginx-config:
	docker exec -it nginx nginx -t

# ============================================================
# 🧹 LARAVEL COMMANDS
# Laravel commands for news-portal (php_news)
laravel-key:
	docker exec -it php_news bash -c "cd /var/www/gramavani && php artisan key:generate"

laravel-cache:
	docker exec -it php_news bash -c "cd /var/www/gramavani && php artisan optimize:clear"

laravel-migrate:
	docker exec -it php_news bash -c "cd /var/www/gramavani && php artisan migrate"

laravel-seed:
	docker exec -it php_news bash -c "cd /var/www/gramavani && php artisan db:seed"

composer-install:
	docker exec -it php_news bash -c "cd /var/www/gramavani && composer install"

npm-install:
	docker exec -it php_news bash -c "cd /var/www/gramavani && npm install"

laravel-build:
	docker exec -it php_news bash -c "cd /var/www/gramavani && npm run build"

laravel-watch:
	docker exec -it php_news bash -c "cd /var/www/gramavani && npm run dev"

# ============================================================
# 💾 DATABASE IMPORT
# Usage: make import dump=/path/to/dump.sql[.zip|.gz]
# ============================================================
import:
	@if [ -z "$(dump)" ]; then \
		echo "❌ Please specify a dump file. Example:"; \
		echo "   make import dump=$(DUMP_DIR)/zesssta-localhost-dump.sql.zip"; \
		exit 1; \
	fi
	@if [ ! -f "$(dump)" ]; then \
		echo "❌ File not found: $(dump)"; \
		exit 1; \
	fi
	@echo "📦 Importing database from: $(dump)"
	@set -a; . ./.env; set +a; \
	case "$(dump)" in \
		*.zip) \
			echo "🗜️  Unzipping and importing..."; \
			unzip -p "$(dump)" | docker exec -i -e MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" $(MDB) mysql -uroot ;; \
		*.gz) \
			echo "🌀  Decompressing and importing..."; \
			gunzip < "$(dump)" | docker exec -i -e MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" $(MDB) mysql -uroot ;; \
		*.sql) \
			echo "🧩  Importing plain SQL file..."; \
			docker exec -i -e MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" $(MDB) mysql -uroot < "$(dump)" ;; \
		*) \
			echo "⚠️  Unsupported file type. Please provide a .sql, .gz, or .zip dump file."; \
			exit 1 ;; \
	esac
	@echo "✅ Import completed."

# ============================================================
# 💾 DATABASE BACKUP
# Usage:
#   make backup db=sprphysio_db
#   make backup-all
# ============================================================

backup:
	@if [ -z "$(db)" ]; then \
		echo "❌ Please specify a database. Example:"; \
		echo "   make backup db=sprphysio_db"; \
		exit 1; \
	fi
	@mkdir -p $(DUMP_DIR)
	@TIMESTAMP=$$(date +'%Y%m%d_%H%M%S'); \
	FILE=$(DUMP_DIR)/$(db)_backup_$${TIMESTAMP}.sql.gz; \
	echo "💾 Backing up $(db) → $${FILE}"; \
	docker exec -e MYSQL_PWD="$$(grep '^MYSQL_ROOT_PASSWORD=' .env | cut -d= -f2-)" $(MDB) \
		mysqldump -uroot --single-transaction "$(db)" | gzip > "$${FILE}"; \
	echo "✅ Backup completed: $${FILE}"

backup-all:
	@mkdir -p $(DUMP_DIR)
	@TIMESTAMP=$$(date +'%Y%m%d_%H%M%S'); \
	FILE=$(DUMP_DIR)/all_databases_backup_$${TIMESTAMP}.sql.gz; \
	echo "💾 Backing up all databases → $${FILE}"; \
	docker exec -e MYSQL_PWD="$$(grep '^MYSQL_ROOT_PASSWORD=' .env | cut -d= -f2-)" $(MDB) \
		mysqldump -uroot --all-databases --single-transaction | gzip > "$${FILE}"; \
	echo "✅ Full backup completed: $${FILE}"
