# Makefile for Platypus

XCODE_PROJ := Platypus.xcodeproj

BUILD_DIR := $(PWD)/products

TEST_TARGET := "CLT Tests"

PLISTBUDDY := "/usr/libexec/PlistBuddy"
INFOPLIST := "Application/Resources/Platypus-Info.plist"
VERSION := $(shell $(PLISTBUDDY) -c "Print :CFBundleShortVersionString" $(INFOPLIST))
APP_NAME := $(shell $(PLISTBUDDY) -c "Print :CFBundleName" $(INFOPLIST))
APP_NAME_LC := $(shell echo "$(APP_NAME)" | tr '[:upper:]' '[:lower:]')
APP_BUNDLE_NAME := $(APP_NAME).app

APP_ZIP_NAME := $(APP_NAME_LC)$(VERSION).zip
APP_SRC_ZIP_NAME := $(APP_NAME_LC)$(VERSION).src.zip

all: clean build_unsigned

release: clean build_signed archives sparkle size

clean:
	xcodebuild clean
	rm -rf $(BUILD_DIR)/*

build_signed:
	@echo Building $(APP_NAME) version $(VERSION) \(signed\)
	mkdir -p $(BUILD_DIR)
	xcodebuild -parallelizeTargets \
        -project "$(XCODE_PROJ)" \
        -target "$(APP_NAME)" \
        -configuration "Deployment" \
        CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
        clean \
        build

build_unsigned:
	@echo Building $(APP_NAME) version $(VERSION) \(unsigned\)
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

archives:
	@echo "Creating application archive ${APP_ZIP_NAME}..."
	@cd $(BUILD_DIR); zip -q --symlinks $(APP_ZIP_NAME) -r $(APP_BUNDLE_NAME)

	@echo "Creating source archive ${APP_SRC_ZIP_NAME}..."
	@cd $(BUILD_DIR); zip -q --symlinks -r "${APP_SRC_ZIP_NAME}" ..  \
	-x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* \
	-x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem* \
	-x \*build/\* -x \*Releases\* -x \*Assets\* -x \*products\* \
	-x \*$(BUILD_DIR)/\*

size:
	@echo "App bundle size:"
	@cd $(BUILD_DIR); du -hs $(APP_BUNDLE_NAME)
	@echo "Binary size:"
	@cd $(BUILD_DIR); stat -f %z $(APP_BUNDLE_NAME)/Contents/MacOS/*
	@echo "Archive Sizes:"
	@cd $(BUILD_DIR); du -hs $(APP_ZIP_NAME)
	@cd $(BUILD_DIR); du -hs $(APP_SRC_ZIP_NAME)

sparkle:
	@echo Generating Sparkle signature
	ruby "Sparkle/sign_update.rb" "$(BUILD_DIR)/$(APP_ZIP_NAME)" "Sparkle/dsa_priv.pem"

clt_tests:
	@echo Running CLT tests
	xcodebuild -parallelizeTargets \
	-project "$(XCODE_PROJ)" \
	-target $(TEST_TARGET) \
	-configuration "Deployment" \
	CONFIGURATION_BUILD_DIR="products" \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	clean \
	build
