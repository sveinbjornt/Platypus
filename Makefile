SHELL := /bin/bash

XCODE_PROJ := Platypus.xcodeproj

SRC_DIR := $(PWD)
BUILD_DIR := /tmp
REMOTE_DIR := root@sveinbjorn.org:/www/sveinbjorn/html/files/software/platypus/

VERSION := $(shell perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($$_=~m/PROGRAM_VERSION.+@.+(\d\.\d+)\"/){print $$1;exit;}}')
APP_NAME := $(shell perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($$_=~m/PROGRAM_NAME.+\"(.+)\"/){print $$1;exit;}}')
# lowercase name
APP_NAME_LC := $(shell echo "$(APP_NAME)" | perl -ne 'print lc')

APP_FOLDER_NAME := $(APP_NAME)-$(VERSION)
APP_BUNDLE_NAME := $(APP_NAME).app

APP_ZIP_NAME := $(APP_NAME_LC)$(VERSION).zip
APP_SRC_ZIP_NAME := $(APP_NAME_LC)$(VERSION).src.zip

.PHONY: build strip dist distApp distSource upload archive sparkle docs all clean

.SILENT:

dist: distApp distSource

all: dist upload archive sparkle docs

clean:
	rm -rf "$(BUILD_DIR)"

build: $(BUILD_DIR)/$(APP_BUNDLE_NAME)

$(BUILD_DIR)/$(APP_BUNDLE_NAME): $(XCODE_PROJ)
	@echo Building $(APP_NAME) version $(VERSION)
	xcodebuild -parallelizeTargets \
	    -project "$(^)" \
		-target "$(APP_NAME)" \
		-configuration "Deployment" \
		CONFIGURATION_BUILD_DIR="$(@D)" \
		clean \
		build
	@echo Build successful
	$(MAKE) strip

define STRIP_BINARY
@PRE_SIZE=$$(stat -f %z "$1"); \
strip -x $1; \
POST_SIZE=$$(stat -f %z "$1"); \
SIZE_PERC=$$((100 - (100 * $${POST_SIZE} / $${PRE_SIZE}))); \
echo "    $$(basename '$1') ($${PRE_SIZE} --> $${POST_SIZE}) (-$${SIZE_PERC})"
endef

strip: $(BUILD_DIR)/$(APP_BUNDLE_NAME)
# Strip executables
# XCode is not to be trusted in such matters
	@echo Stripping binaries
	$(call STRIP_BINARY,$(<)/Contents/MacOS/Platypus)
	$(call STRIP_BINARY,$(<)/Contents/Resources/ScriptExec)
	$(call STRIP_BINARY,$(<)/Contents/Resources/platypus_clt)

distApp: $(BUILD_DIR)/$(APP_ZIP_NAME)

$(BUILD_DIR)/$(APP_FOLDER_NAME): $(BUILD_DIR)/$(APP_BUNDLE_NAME)
# Remove previous app folder
	rm -rf "$(@)"
# Create folder and copy app into it
	@echo Creating app folder $(@)
	mkdir "$(@)"
	cp -r "$(<)" "$(@)/"
# Remove DS_Store junk
	find "$(@)" -name ".DS_Store" -exec rm -f "{}" \;
	@echo Creating symlink to Readme file
	ln -s "$(<F)/Contents/Resources/Readme.html" "$(@)/Readme.html"

$(BUILD_DIR)/$(APP_ZIP_NAME): $(BUILD_DIR)/$(APP_FOLDER_NAME)
	@echo Creating application archive $(@F)...
	cd "$(@D)"; zip -q --symlinks "$(@F)" -r "$(<F)"

distSource: $(BUILD_DIR)/$(APP_SRC_ZIP_NAME)

$(BUILD_DIR)/$(APP_SRC_ZIP_NAME): | $(SRC_DIR)
	@echo Creating source archive $(@F)...
	cd "$(|)"; zip -q --symlinks -r "$(@F)" . \
		-x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* \
		-x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem* \
		-x \*build/\* -x \*Releases\* -x \*Assets\* \
		-x \*$(BUILD_DIR)/\*
	mv "$(|)/$(@F)" "$(@)"

upload: $(addprefix $(BUILD_DIR)/,$(APP_ZIP_NAME) $(APP_SRC_ZIP_NAME))
	@echo Uploading archives ...
	scp "$(^)" "$(REMOTE_DIR)"

archive: $(addprefix $(HOME)/Desktop/,$(APP_ZIP_NAME) $(APP_SRC_ZIP_NAME))
	@echo Archive Sizes:
	du -hs $(^)

$(HOME)/Desktop/%.zip: $(BUILD_DIR)/%.zip
	@echo Copying $(<F) to Desktop
	cp "$(<)" "$(@)"

sparkle: $(HOME)/Desktop/$(APP_ZIP_NAME)
	@echo Generating Sparkle signature
	ruby "Sparkle/sign_update.rb" "$(<)" "Sparkle/dsa_priv.pem"

docs:
	@echo Updating Documentation.html on server ...
	cd Documentation; sh "update_docs.sh"
	@echo Updating HTML man page on server ...
	cd CommandLineTool/man/; sh "update_online_manpage.sh"
