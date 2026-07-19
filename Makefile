# Makefile for EquationCraft macOS Application

APP_NAME = EquationCraft
APP_DIR = $(APP_NAME).app
MACOS_DIR = $(APP_DIR)/Contents/MacOS
RESOURCES_DIR = $(APP_DIR)/Contents/Resources
PLIST_FILE = $(APP_DIR)/Contents/Info.plist

SOURCES = main.swift AppDelegate.swift MathAutocorrect.swift MacEditorView.swift WebViewWrapper.swift ContentView.swift

all: build

build:
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	@if [ ! -f Resources/tex-svg.js ]; then \
		echo "Downloading MathJax JS library for offline rendering..."; \
		curl -s -L https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js -o Resources/tex-svg.js; \
	fi
	swiftc -O $(SOURCES) -target arm64-apple-macosx11.0 -o equation-craft-arm64
	swiftc -O $(SOURCES) -target x86_64-apple-macosx11.0 -o equation-craft-x86
	lipo -create equation-craft-arm64 equation-craft-x86 -output "$(MACOS_DIR)/EquationCraft"
	rm equation-craft-arm64 equation-craft-x86
	cp Info.plist "$(PLIST_FILE)"
	cp -R Resources/ "$(RESOURCES_DIR)/"
	codesign --force --deep --sign - "$(APP_DIR)"
	@echo "Build successful! Created $(APP_DIR)"

run: build
	open "$(APP_DIR)"

clean:
	rm -rf "$(APP_DIR)"
	@echo "Cleaned build artifacts."

.PHONY: all build run clean
