## This project currently requires GNU Make.

# /*TODO:*/ It would be nice to force an error if this is run in non-GNU POSIX
# make, but this is difficult since POSIX make doesn't explicitly support
# conditionals.

# Alternatively, we could validate that we only use POSIX make compatible
# syntax.



### Project paths:
PROJECT_BASE_PATH      := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
DEPS_DIR               := $(PROJECT_BASE_PATH)/deps


# As suggested here: https://stackoverflow.com/questions/58367235/how-to-detect-if-the-makefile-silent-quiet-command-line-option-was-set
# Set SILENT to 's' if --quiet/-s set, otherwise ''.
SILENT_MODE  := $(findstring s,$(word 1, $(MAKEFLAGS)))

VERBOSE_MODE := $(filter verbose,$(MAKECMDGOALS))
SILENCE_WHEN_NOT_VERBOSE := $(if $(VERBOSE_MODE),,@)

## Functions:
# SH__BUILTIN_FRIENDLY_WHICH
# BUILTIN_FRIENDLY_WHICH
#     Resolves a command to a path only if it resolves to an executable
#     file. If the command isn't defined, it resolves to the empty string.
#     Otherwise (if it's a builtin, alias or function) it returns the
#     unmodified command name. This allows reproducing execution of a
#     command from the build output that might have a different PATH than
#     the shell of the Makefile.
#
#     The SH__ variant is intended to be run within a shell, producing the
#     result to stdout, while the unprefixed varient expands to an inline
#     string within the Makefile.
#   PARAMETERS:
#     1: The command to resolve
SH__BUILTIN_FRIENDLY_WHICH = \
    cmd_path="$$(which "$(1)")" && \
        if [ -x "$$cmd_path" ] ; then \
            echo "$$cmd_path" ; \
        else \
            echo "$(1)"; \
        fi
BUILTIN_FRIENDLY_WHICH     = $(shell $(call SH__BUILTIN_FRIENDLY_WHICH,$(1)))

### Binaries we use:
CAT            := $(call BUILTIN_FRIENDLY_WHICH,cat)
RM             := $(call BUILTIN_FRIENDLY_WHICH,rm)
MKDIR          := $(call BUILTIN_FRIENDLY_WHICH,mkdir)
ECHO           := $(call BUILTIN_FRIENDLY_WHICH,echo)
TEE            := $(call BUILTIN_FRIENDLY_WHICH,tee)
# FIND           := $(call BUILTIN_FRIENDLY_WHICH,find)
GIT            := $(call BUILTIN_FRIENDLY_WHICH,git)
CURL           := $(call BUILTIN_FRIENDLY_WHICH,curl)
WGET           := $(call BUILTIN_FRIENDLY_WHICH,wget)
DOCKER         := $(call BUILTIN_FRIENDLY_WHICH,docker)
DOCKER_COMPOSE := $(call BUILTIN_FRIENDLY_WHICH,docker-compose)
# $(SHELL) will usually be either of these two
BOURNE_SHELL   := $(call BUILTIN_FRIENDLY_WHICH,sh)
BASH_SHELL     := $(call BUILTIN_FRIENDLY_WHICH,bash)

### Install paths for ShellSpec:
SHELLSPEC_BASE_INSTALL_DIR := $(DEPS_DIR)/shellspec
SHELLSPEC_BIN_DIR          := $(SHELLSPEC_BASE_INSTALL_DIR)/bin
SHELLSPEC_INSTALL_DIR      := $(SHELLSPEC_BASE_INSTALL_DIR)/lib
SHELLSPEC_INSTALLER_URL    := https://git.io/shellspec
SHELLSPEC_VERSION_FILE     := $(DEPS_DIR)/shellspec.ver_lock
SHELLSPEC_VERSION           = $(shell $(CAT) $(SHELLSPEC_VERSION_FILE))
SHELLSPEC                  := $(SHELLSPEC_BIN_DIR)/shellspec
SHELLSPEC_OUTPUT_DIR       := $(PROJECT_BASE_PATH)/output
SHELLSPEC_REPORT_DIR       := $(PROJECT_BASE_PATH)/report
SHELLSPEC_COVERAGE_DIR     := $(PROJECT_BASE_PATH)/coverage
SHELLSPEC_OUTPUT_LOG       := $(SHELLSPEC_OUTPUT_DIR)/shellspec_success.log

DOWNLOAD_URL_TO_STDOUT := $(if $(CURL),$(CURL) -fsSL,$(if $(WGET),$(WGET) -O-,))

SH__ESCAPE_FOR_SQUOTES   = $(subst ','\'',$(1))
# SH__ESCAPE_FOR_DQUOTES   = $(subst ",\",$(subst $$,\$$,$(1)))
SH__RUN_CMD_IN_SPECIFIED_SHELL = $(if $(filter $(firstword $(3) $(SHELL)),$(2)),$(1),$(2) -c '$(call SH__ESCAPE_FOR_SQUOTES,$(1))')
SH__ENABLE_PIPEFAIL_FOR_COMMAND = $(call SH__RUN_CMD_IN_SPECIFIED_SHELL,set -o pipefail ; $(1),$(BASH_SHELL),$(2))
# We automatically silence this when in SILENT_MODE
SH__ECHO_THEN_EXECUTE    = $(if $(SILENT_MODE),,>&2 $(ECHO) '$(call SH__ESCAPE_FOR_SQUOTES,$(1))' ; )$(1)
SH__ECHO_THEN_EXECUTE_IF = if $(1) ; then $(call SH__ECHO_THEN_EXECUTE,$(2)) ; fi

SHELLSPEC_OUTPUT_DIRS = $(SHELLSPEC_OUTPUT_DIR) $(SHELLSPEC_REPORT_DIR) $(SHELLSPEC_COVERAGE_DIR)

GENERATED_DIRS = $(SHELLSPEC_OUTPUT_DIRS)

GENERATED = $(GENERATED_DIRS)

DOWNLOADED = $(SHELLSPEC_BASE_INSTALL_DIR)

define GENERATE_SHELLSPEC_TESTS_RULE

$(1): $(SHELLSPEC) $(SHELLSPEC_OUTPUT_DIRS) $(2) $(wildcard spec/*_spec.sh) \
                                                 $(wildcard spec/*_helper.sh) \
                              $(foreach dep_file,$(wildcard spec/*_spec.deps),$(shell $(CAT) $(dep_file)))
	$(call SH__ENABLE_PIPEFAIL_FOR_COMMAND,\
		($(SHELLSPEC) --color | $(TEE) $(SHELLSPEC_OUTPUT_LOG)) || \
			($(RM) -f $(SHELLSPEC_OUTPUT_LOG) ; exit 1)\
	)


endef

define GENERATE_GENERATED_DIR_RULE


$(1):
	$(SILENCE_WHEN_NOT_VERBOSE)$(call SH__ECHO_THEN_EXECUTE_IF,! [ -d "$(1)" ],$(MKDIR) -p $(1))


endef

all: test_cachable

.PHONY: all test test_cachable test_force clean dist_clean

test: test_force

test_cachable: $(SHELLSPEC_OUTPUT_LOG)


$(eval \
        $(call GENERATE_SHELLSPEC_TESTS_RULE,$(SHELLSPEC_OUTPUT_LOG),) \
        $(call GENERATE_SHELLSPEC_TESTS_RULE,test_force,FORCE) \
        $(foreach dir_name,$(GENERATED_DIRS),$(call GENERATE_GENERATED_DIR_RULE,$(dir_name))))


$(SHELLSPEC): $(SHELLSPEC_VERSION_FILE)
	$(SILENCE_WHEN_NOT_VERBOSE)if [ '$(DOWNLOAD_URL_TO_STDOUT)' = '' ]; then \
		>&2 $(ECHO) "Either curl or wget must be installed to install" \
			"ShellSpec via https. Neither binary found in current PATH." ; \
		exit 1 ; \
	fi
	$(SILENCE_WHEN_NOT_VERBOSE)if [ '$(GIT)' = '' ]; then \
		>&2 $(ECHO) "git must be installed to install" \
			"ShellSpec. Git binary not found in current PATH." ; \
		exit 1 ; \
	fi
	$(SILENCE_WHEN_NOT_VERBOSE)$(call SH__ECHO_THEN_EXECUTE_IF,[ -e "$(SHELLSPEC_BASE_INSTALL_DIR)" ],$(RM) -rf "$(SHELLSPEC_BASE_INSTALL_DIR)")
	$(call SH__ENABLE_PIPEFAIL_FOR_COMMAND,\
		$(DOWNLOAD_URL_TO_STDOUT) $(SHELLSPEC_INSTALLER_URL) | \
			$(BOURNE_SHELL) \
				-s $(SHELLSPEC_VERSION) \
				--bin "$(SHELLSPEC_BIN_DIR)" \
				--dir "$(SHELLSPEC_INSTALL_DIR)" \
				--yes \
	)

clean: FORCE
	rm -rf $(GENERATED)

dist_clean: FORCE
	rm -rf $(GENERATED) $(DOWNLOADED)


# Dummy target, to put makefile into verbose mode.
# The dependancy expands to "all" there are no explicit goals besides
# "verbose"
verbose: $(if $(filter-out verbose,$(MAKECMDGOALS)),,all)

FORCE:


