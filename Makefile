# Makefile for Jan Electron App - Build, Lint, Test, and Clean

# Default target, does nothing
all:
	@echo "Specify a target to run"

# Builds the UI kit
build-uikit:
ifeq ($(OS),Windows_NT)
	cd uikit && yarn config set network-timeout 300000 && yarn install && yarn build
else
	cd uikit && yarn install && yarn build
endif

# Installs yarn dependencies and builds core and extensions
install-and-build: build-uikit
ifeq ($(OS),Windows_NT)
	yarn config set network-timeout 300000
endif
	yarn global add turbo
	yarn build:core
	yarn build:server
	yarn install
	yarn build:extensions

check-file-counts: install-and-build
ifeq ($(OS),Windows_NT)
	powershell -Command "if ((Get-ChildItem -Path pre-install -Filter *.tgz | Measure-Object | Select-Object -ExpandProperty Count) -ne (Get-ChildItem -Path extensions -Directory | Where-Object Name -like *-extension* | Measure-Object | Select-Object -ExpandProperty Count)) { Write-Host 'Number of .tgz files in pre-install does not match the number of subdirectories in extensions with package.json'; exit 1 } else { Write-Host 'Extension build successful' }"
else
	@tgz_count=$$(find pre-install -type f -name "*.tgz" | wc -l); dir_count=$$(find extensions -mindepth 1 -maxdepth 1 -type d -exec test -e '{}/package.json' \; -print | wc -l); if [ $$tgz_count -ne $$dir_count ]; then echo "Number of .tgz files in pre-install ($$tgz_count) does not match the number of subdirectories in extension ($$dir_count)"; exit 1; else echo "Extension build successful"; fi
endif

dev: check-file-counts
	yarn dev

# Linting
lint: check-file-counts
	yarn lint

# Testing
test: lint
	yarn build:test
	yarn test:unit
	yarn test

# Builds and publishes the app
build-and-publish: check-file-counts
	yarn build:publish

# Build
build: check-file-counts
	yarn build

clean:
ifeq ($(OS),Windows_NT)
	powershell -Command "Get-ChildItem -Path . -Include node_modules, .next, dist, build, out -Recurse -Directory | Remove-Item -Recurse -Force"
	powershell -Command "Get-ChildItem -Path . -Include package-lock.json -Recurse -File | Remove-Item -Recurse -Force"
	powershell -Command "Remove-Item -Recurse -Force ./pre-install/*.tgz"
	powershell -Command "Remove-Item -Recurse -Force ./electron/pre-install/*.tgz"
	powershell -Command "if (Test-Path \"$($env:USERPROFILE)\jan\extensions\") { Remove-Item -Path \"$($env:USERPROFILE)\jan\extensions\" -Recurse -Force }"
else ifeq ($(shell uname -s),Linux)
	find . -name "node_modules" -type d -prune -exec rm -rf '{}' +
	find . -name ".next" -type d -exec rm -rf '{}' +
	find . -name "dist" -type d -exec rm -rf '{}' +
	find . -name "build" -type d -exec rm -rf '{}' +
	find . -name "out" -type d -exec rm -rf '{}' +
	find . -name "packake-lock.json" -type f -exec rm -rf '{}' +
	rm -rf ./pre-install/*.tgz
	rm -rf ./electron/pre-install/*.tgz
	rm -rf "~/jan/extensions"
	rm -rf "~/.cache/jan*"
else
	find . -name "node_modules" -type d -prune -exec rm -rf '{}' +
	find . -name ".next" -type d -exec rm -rf '{}' +
	find . -name "dist" -type d -exec rm -rf '{}' +
	find . -name "build" -type d -exec rm -rf '{}' +
	find . -name "out" -type d -exec rm -rf '{}' +
	find . -name "packake-lock.json" -type f -exec rm -rf '{}' +
	rm -rf ./pre-install/*.tgz
	rm -rf ./electron/pre-install/*.tgz
	rm -rf ~/jan/extensions
	rm -rf ~/Library/Caches/jan*
endif
