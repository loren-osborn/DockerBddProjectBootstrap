## This project currently requires GNU Make.

# /*TODO:*/ It would be nice to force an error if this is run in non-GNU POSIX
# make, but this is difficult since POSIX make doesn't explicitly support
# conditionals.

# Alternatively, we could validate that we only use POSIX make compatible
# syntax.



### Project paths:
PROJECT_BASE_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DEPS_DIR          := $(PROJECT_BASE_PATH)/deps

### Install paths for ShellSpec:
SHELLSPEC_BASE_INSTALL_DIR := $(DEPS_DIR)/shellspec
SHELLSPEC_BIN_DIR          := $(SHELLSPEC_BASE_INSTALL_DIR)/bin
SHELLSPEC_INSTALL_DIR      := $(SHELLSPEC_BASE_INSTALL_DIR)/lib
SHELLSPEC_INSTALLER_URL    := https://git.io/shellspec
SHELLSPEC_VERSION           = $(shell cat $(DEPS_DIR)/shellspec.lock)

### Binaries we use:
SHELLSPEC      := $(SHELLSPEC_BIN_DIR)/shellspec
GIT            := $(shell which git)
CURL           := $(shell which curl)
WGET           := $(shell which wget)
DOCKER         := $(shell which docker)
DOCKER_COMPOSE := $(shell which docker-compose)
# $(CURRENT_SHELL) will usually be either of these two
CURRENT_SHELL  := $(SHELL)
BOURNE_SHELL   := $(shell which sh)
BASHSHELL      := $(shell which bash)

ifneq (,$(CURL))
DOWNLOAD_URL_TO_STDOUT := $(CURL) -fsSL
else
ifneq (,$(WGET))
DOWNLOAD_URL_TO_STDOUT := $(WGET) -O-
else
endif
endif

test: $(SHELLSPEC)
	echo Run tests here.


$(SHELLSPEC):
	@if [ '$(DOWNLOAD_URL_TO_STDOUT)' = '' ]; then \
		>&2 echo "Either curl or wget must be installed to install" \
			"ShellSpec via https. Neither binary found in current PATH." ; \
		exit 1 ; \
	fi
	@if [ '$(GIT)' = '' ]; then \
		>&2 echo "git must be installed to install" \
			"ShellSpec. Git binary not found in current PATH." ; \
		exit 1 ; \
	fi
	$(DOWNLOAD_URL_TO_STDOUT) $(SHELLSPEC_INSTALLER_URL) | \
		$(BOURNE_SHELL) \
			-s $(SHELLSPEC_VERSION) \
			--bin "$(SHELLSPEC_BIN_DIR)" \
			--dir "$(SHELLSPEC_INSTALL_DIR)" \
			--yes


