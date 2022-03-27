FIG = docker compose
EXEC = $(FIG) exec app
RUN = $(FIG) run app
RAILS = $(EXEC) rails

# Containers commands
build:
	@$(FIG) build
up:
	@$(FIG) up
sh:
	@$(RUN) bash
down:
	@$(FIG) down
restart:
	@$(FIG) stop
	@$(FIG) start

# Clean up
clean:
	@docker system prune

# Bundle
bi:
	@$(EXEC) bundle install
br:
	@$(EXEC) gem uninstall -aIx
	@make bi

# Rails
rc:
	@$(RAILS) console
rr:
	@$(RAILS) routes
rt:
	@$(RAILS) test

# DB
dbc:
	@$(RAILS) db:create
dbm:
	@$(RAILS) db:migrate
dbs:
	@$(RAILS) db:seed
