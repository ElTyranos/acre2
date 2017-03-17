PREFIX = acre
BIN = @acre2
ZIP = acre2
FLAGS = -i include -w unquoted-string -w redefinition-wo-undef

MAJOR = $(shell grep "^\#define[[:space:]]*MAJOR" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
MINOR = $(shell grep "^\#define[[:space:]]*MINOR" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
PATCH = $(shell grep "^\#define[[:space:]]*PATCHLVL" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
BUILD = $(shell grep "^\#define[[:space:]]*BUILD" addons/main/script_version.hpp | egrep -m 1 -o '[[:digit:]]+')
VERSION = $(MAJOR).$(MINOR).$(PATCH)
VERSION_FULL = $(VERSION).$(BUILD)

$(BIN)/addons/$(PREFIX)_%.pbo: addons/%
	@mkdir -p $(BIN)/addons
	@echo "  PBO  $@"
	@armake build ${FLAGS} -f $< $@

$(BIN)/optionals/$(PREFIX)_%.pbo: optionals/%
	@mkdir -p $(BIN)/optionals
	@echo "  PBO  $@"
	@armake build ${FLAGS} -f $< $@

# Shortcut for building single addons (eg. "make <component>.pbo")
%.pbo:
	"$(MAKE)" $(MAKEFLAGS) $(patsubst %, $(BIN)/addons/$(PREFIX)_%, $@)

all: $(patsubst addons/%, $(BIN)/addons/$(PREFIX)_%.pbo, $(wildcard addons/*)) \
		$(patsubst optionals/%, $(BIN)/optionals/$(PREFIX)_%.pbo, $(wildcard optionals/*))

filepatching:
	"$(MAKE)" $(MAKEFLAGS) FLAGS="-w unquoted-string -p"

$(BIN)/keys/%.biprivatekey:
	@mkdir -p $(BIN)/keys
	@echo "  KEY  $@"
	@armake keygen -f $(patsubst $(BIN)/keys/%.biprivatekey, $(BIN)/keys/%, $@)

$(BIN)/addons/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL).bisign: $(BIN)/addons/$(PREFIX)_%.pbo $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey
	@echo "  SIG  $@"
	@armake sign -f $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey $<

$(BIN)/optionals/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL).bisign: $(BIN)/optionals/$(PREFIX)_%.pbo $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey
	@echo "  SIG  $@"
	@armake sign -f $(BIN)/keys/$(PREFIX)_$(VERSION_FULL).biprivatekey $<

signatures: $(patsubst addons/%, $(BIN)/addons/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL).bisign, $(wildcard addons/*)) \
		$(patsubst optionals/%, $(BIN)/optionals/$(PREFIX)_%.pbo.$(PREFIX)_$(VERSION_FULL).bisign, $(wildcard optionals/*))

extensions: $(wildcard extensions/*/*)
	cd extensions/vcproj && cmake .. && make

extensions-win64: $(wildcard extensions/*/*)
	cd extensions/vcproj64 && CXX=$(eval $(which g++-w64-mingw-i686)) cmake .. && make

clean:
	rm -rf $(BIN) $(ZIP)_*.zip

release:
	@"$(MAKE)" clean
	@"$(MAKE)" $(MAKEFLAGS) signatures
	@echo "  ZIP  $(ZIP)_$(VERSION).zip"
	@cp *.dll acre_logo_medium_ca.paa LICENSE meta.cpp mod.cpp README.md $(BIN)
	@cp -r extras/userconfig $(BIN)/optionals
	@zip -r $(ZIP)_$(VERSION).zip $(BIN) &> /dev/null

.PHONY: release