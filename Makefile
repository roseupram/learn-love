Release_dir := $(HOME)/desktop
LOVE_FILE :=$(Release_dir)/game.love

RESTORE_FILE := conf.lua main.lua
MAKEFLAGS += -s
.PHONY: all build restore $(LOVE_FILE)


all: build

build: remove-debug $(LOVE_FILE) restore

$(LOVE_FILE):
	@echo "enable fullscreen"
	sed -i.bak /fullscreen/s/false/true/ conf.lua
	mkdir -p $(Release_dir)
	@echo "zip to love"
	zip $@ -ru * -x release "*.bak"

remove-debug: main.lua
	@echo "remove debug"
	sed -i.bak /^[^-].*lldebug/s/^/--/ main.lua

enable-debug: main.lua
	@echo "enable debug"
	sed -i.bak '/^-\{2,\}.*lldebug/s/^-*//' $<

restore:
	for f in $(RESTORE_FILE); do \
		echo "restore $$f"; \
		[ -f "$$f.bak" ] && mv -f "$$f.bak" "$$f" || true; \
	done