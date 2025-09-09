Release_dir := $(HOME)/desktop
LOVE_FILE :=$(Release_dir)/game.love
M4_FILE := $(wildcard shader/*.m4.glsl)
SHADER_OUT := $(subst m4,out,$(M4_FILE))

RESTORE_FILE := conf.lua main.lua
# MAKEFLAGS += -s
.PHONY: all build restore $(LOVE_FILE) shader-compile


all: build

build: remove-debug shader-compile $(LOVE_FILE) restore

$(LOVE_FILE):
	@echo "enable fullscreen"
	sed -i.bak /fullscreen/s/false/true/ conf.lua
	mkdir -p $(Release_dir)
	@echo "zip to love"
	zip $@ -ru * -x release "*.bak" "*.m4.glsl"

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

print:
	echo $(SHADER_OUT)
shader-compile: $(SHADER_OUT)

%.out.glsl: %.m4.glsl | shader/lib/*
	m4 -I shader $< > $@
