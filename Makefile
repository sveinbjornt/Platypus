# Makefile for Platypus

XCODE_PROJ := Platypus.xcodeproj

SRC_DIR := $(PWD)
BUILD_DIR := $(PWD)/products

PLISTBUDDY := "/usr/libexec/PlistBuddy"
INFOPLIST := "Application/Resources/Platypus-Info.plist"
VERSION := $(shell $(PLISTBUDDY) -c "Print :CFBundleShortVersionString" $(INFOPLIST))
APP_NAME := $(shell $(PLISTBUDDY) -c "Print :CFBundleName" $(INFOPLIST))
APP_NAME_LC := $(shell echo "$(APP_NAME)" | tr '[:upper:]' '[:lower:]')

APP_BUNDLE_NAME := $(APP_NAME).app

APP_ZIP_NAME := $(APP_NAME_LC)$(VERSION).zip
APP_SRC_ZIP_NAME := $(APP_NAME_LC)$(VERSION).src.zip

all: clean build_unsigned

release: clean build_signed archives size

clean:
	xcodebuild clean
	rm -rf $(BUILD_DIR)/*

build_signed:
	@echo Building $(APP_NAME) version $(VERSION)
	mkdir -p $(BUILD_DIR)
	xcodebuild -parallelizeTargets \
        -project "$(XCODE_PROJ)" \
        -target "$(APP_NAME)" \
        -configuration "Deployment" \
        CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
        clean \
        build

build_unsigned:
	@echo Building $(APP_NAME) version $(VERSION)
	mkdir -p $(BUILD_DIR)
	xcodebuild -parallelizeTargets \
        -project "$(XCODE_PROJ)" \
        -target "$(APP_NAME)" \
        -configuration "Deployment" \
        CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        clean \
        build

distApp: $(BUILD_DIR)/$(APP_ZIP_NAME)
	@echo Creating application archive $(@F)...
	cd "$(@D)"; zip -q --symlinks "$(@F)" -r "$(<F)"

distSource: $(BUILD_DIR)/$(APP_SRC_ZIP_NAME)

$(BUILD_DIR)/$(APP_SRC_ZIP_NAME): | $(SRC_DIR)
	@echo Creating source archive $(@F)...
	cd "$(|)"; zip -q --symlinks -r "$(@F)" . \
	    -x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* \
	    -x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem* \
	    -x \*build/\* -x \*Releases\* -x \*Assets\* -x \*products\* \
	    -x \*$(BUILD_DIR)/\*
	mv "$(|)/$(@F)" "$(@)"


archive: $(addprefix $(HOME)/Desktop/,$(APP_ZIP_NAME) $(APP_SRC_ZIP_NAME))
	@echo Archive Sizes:
	du -hs $(^)

sparkle: $(HOME)/Desktop/$(APP_ZIP_NAME)
	@echo Generating Sparkle signature
	ruby "Sparkle/sign_update.rb" "$(<)" "Sparkle/dsa_priv.pem"
