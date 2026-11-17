APP_NAME := Sidekick
RELEASE_DIR := .build/release
APP_BUNDLE := build/$(APP_NAME).app
INSTALL_DIR := $(HOME)/Applications
SIGN_IDENTITY ?= Sidekick app certificate
# The Command Line Tools lack the compiler plugins for SwiftUI's macros, such as @State and @Entry.
export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: build test app install run clean

build:
	swift build -c release

test:
	swift test

app: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(RELEASE_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Support/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@if security find-identity -p codesigning | grep -q "$(SIGN_IDENTITY)"; then \
		codesign --force --sign "$(SIGN_IDENTITY)" $(APP_BUNDLE); \
	else \
		echo "warning: no \"$(SIGN_IDENTITY)\" certificate in the keychain, signing ad hoc."; \
		echo "warning: macOS will ask for access to the tasks file again after every install."; \
		codesign --force --sign - $(APP_BUNDLE); \
	fi

install: app
	-pkill -x $(APP_NAME)
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	mkdir -p $(INSTALL_DIR)
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	open $(INSTALL_DIR)/$(APP_NAME).app

run:
	swift build
	.build/debug/$(APP_NAME)

clean:
	rm -rf .build build
