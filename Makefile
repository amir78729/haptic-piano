.DEFAULT_GOAL := help

.PHONY: help build test verify run install clean

help:
	@printf '%s\n' \
	  'Haptic Piano commands:' \
	  '  make build    Build build/HapticPiano.app' \
	  '  make test     Run the dependency-free domain checks' \
	  '  make verify   Run checks and build the app bundle' \
	  '  make run      Build and open the app' \
	  '  make install  Build and install to ~/Applications' \
	  '  make clean    Remove generated build artifacts'

build:
	./build.sh

test:
	./check.sh

verify: test build

run: build
	open build/HapticPiano.app

install: build
	mkdir -p "$(HOME)/Applications"
	rm -rf "$(HOME)/Applications/HapticPiano.app"
	cp -R build/HapticPiano.app "$(HOME)/Applications/HapticPiano.app"
	@printf '%s\n' 'Installed Haptic Piano to $(HOME)/Applications/HapticPiano.app'

clean:
	rm -rf build .build
