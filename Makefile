#!/bin/bash
THIS_FILE := $(lastword $(MAKEFILE_LIST))
#envs
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# Colors
NO_COLOR?=\x1b[0m
OK_COLOR?=\x1b[32;01m
ERROR_COLOR?=\x1b[31;01m
WARN_COLOR?=\x1b[33;01m

ECHO?=/bin/echo -e
SED?=/bin/sed -i

#guid/uid
export UID = $(shell id -u)
export GID = $(shell id -g)

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

clean:
	@ printf '$(ERROR_COLOR)Cleaning folder...$(NO_COLOR)'
	@ rm -rf "./app"
	@ rm -rf "./logs"
	@ printf '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)\n'

init-app: ## Init app folder
	@ if [ ! -d "$(MAJORDOMO_ROOT)" ]; then \
		$(ECHO) -n 'Make app folder...'; \
		mkdir -p $(MAJORDOMO_ROOT); \
		$(ECHO) '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)'; \
		$(ECHO) -n 'Clone majordomo repository...'; \
		$(ECHO) '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)'; \
		git clone -b master https://github.com/sergejey/majordomo.git $(MAJORDOMO_ROOT); \
	fi
	@ if [ ! -f $(MAJORDOMO_ROOT)/config.php ]; then \
		$(ECHO) -n 'Make $(MAJORDOMO_ROOT)/config.php...'; \
		cp $(MAJORDOMO_ROOT)/config.php.sample $(MAJORDOMO_ROOT)/config.php; \
		$(SED) "s/'DB_HOST', 'localhost'/'DB_HOST', \$$_ENV['MYSQL_HOST']/g" $(MAJORDOMO_ROOT)/config.php; \
		$(SED) "s/'DB_USER', 'root'/'DB_USER', \$$_ENV['MYSQL_USER']/g" $(MAJORDOMO_ROOT)/config.php; \
		$(SED) "s/'DB_PASSWORD', ''/'DB_PASSWORD', \$$_ENV['MYSQL_PASSWORD']/g" $(MAJORDOMO_ROOT)/config.php; \
		$(ECHO) '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)'; \
	fi

init-db: ## Init database
	@ if [ ! -d "$(MAJORDOMO_ROOT)" ]; then \
		$(ECHO) '$(WARN_COLOR)"app" folder not found. Run `make init-app` first$(NO_COLOR)'; \
		exit 1; \
	fi
	@ if [ ! -d "./app/data" ]; then \
		mkdir -p ./app/data; \
	fi
	@$(ECHO) -n 'Starting "database"...'
	@ docker-compose up -d database > /dev/null 2>&1
	@ while ! docker ps | grep database > /dev/null 2>&1; do sleep 1; done
	@$(ECHO) '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)'

	@$(ECHO) -n 'Creating DB, User and previlegies...'
	@ docker-compose exec database bash -c 'while ! mysql -p$(MYSQL_ROOT_PASSWORD) -e "SHOW DATABASES" > /dev/null 2>&1; do sleep 1; done && \
		mysql -p$(MYSQL_ROOT_PASSWORD) -e "DROP DATABASE IF EXISTS $(MYSQL_DATABASE); \
		CREATE DATABASE $(MYSQL_DATABASE); \
		DROP USER IF EXISTS $(MYSQL_USER)@\"%\"; \
		CREATE USER IF NOT EXISTS $(MYSQL_USER)@\"%\" IDENTIFIED BY \"$(MYSQL_PASSWORD)\"; \
		GRANT ALL ON $(MYSQL_DATABASE).* TO $(MYSQL_USER)@\"%\"; \
		GRANT RELOAD ON *.* TO $(MYSQL_USER)@\"%\"; \
		FLUSH PRIVILEGES; \
		"'
	@$(ECHO) '\t\t$(OK_COLOR)[OK]$(NO_COLOR)'

	@$(ECHO) -n 'Loading dump file...'
	@ cat $(MAJORDOMO_ROOT)/db_terminal.sql | docker-compose exec -T database mysql -p$(MYSQL_ROOT_PASSWORD) $(MYSQL_DATABASE)
	@$(ECHO) '\t\t\t\t$(OK_COLOR)[OK]$(NO_COLOR)'
	#@docker-compose rm -sf database > /dev/null 2>&1 &

build: ## Build docker containers
	@$(call docker_compose, build)
	
up: ## Up docker containers
	@$(call docker_compose, up -d)

stop: ## Stop docker containers
	@$(call docker_compose, stop)

restart: ## Restart docker containers
	@$(call docker_compose, restart)

ps: ## Ps docker containers
	@$(call docker_compose, ps)

exec-mysql: ## Enter to mysql container
	@$(call docker_compose, exec database bash)
	
install: ## first start
	@ make init-app
	@ make build
	@ sudo chmod -R 777 $(DOCUMENT_ROOT)/*
	@ make init-db
	@ make up


%:
    @:
define docker_compose
    @docker-compose -f ./docker-compose.yml $(1)
endef
