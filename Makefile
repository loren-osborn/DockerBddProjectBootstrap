## This project currently requires GNU Make.

# /*TODO:*/ It would be nice to force an error if this is run in non-GNU POSIX
# make, but this is difficult since POSIX make doesn't explicitly support
# conditionals.

# Alternatively, we could validate that we only use POSIX make compatible
# syntax.

### Project paths:
PROJECT_BASE_PATH        := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))


# As suggested here: https://stackoverflow.com/questions/58367235/how-to-detect-if-the-makefile-silent-quiet-command-line-option-was-set
# Set SILENT to 's' if --quiet/-s set, otherwise ''.
# This allows us to silence command eching when we're doing it manually.
# See FN__SH__ECHO_THEN_EXECUTE.
SILENT_MODE              := $(findstring s,$(word 1, $(MAKEFLAGS)))

# Here we detect a phony target (used as the antithesis of SILENT_MODE) to
# echo all commands in recipes by removing the `@` at the beginning of recipe
# lines.

# As GNU Make provides no way to do this, we use $(SILENCE_WHEN_NOT_VERBOSE) in
# place of `@` at the beginning of recipe lines, so we can easily remove them.
VERBOSE_MODE             := $(filter verbose,$(MAKECMDGOALS))
SILENCE_WHEN_NOT_VERBOSE := $(if $(VERBOSE_MODE),,@)

## Common makefile special-character aliases:
DOLLARS                  := $$
# BLANK                    :=
# SPACE                    := $(BLANK) $(BLANK)
# OPEN_PAREN               := (
# CLOSE_PAREN              := )
# COMMA                    := ,


### All macros with the name prefix "FN__" are GNU Make fumctions, and must be
#   be expanded with $(call FN__MACRO_NAME,Arg1,Arg2,Arg3)

### Function names beginning with "FN__SH__" expand to POSIX shell code
#   intended to be used in that context (either for use within a `$(shell ...)`
#   function, or as part of a target recipe)

### Function names beginning with "FN__EVAL__" expand to GNU Make code
#   intended to be used within `$(eval $(call FN__EVAL__...))`


## Function:
# FN__EVAL__DEFINE_MACRO
#     Allows a Make macro to be defined within a a macro expansion. This is
#     helpful preserving state within an "deferred macro" expansion. The
#     default behavior is an immediate assignment with := but this can be
#     overridden.
#   PARAMETERS:
#     1: The name of the new macro to define
#     2: The new macro's value
#     3: The assignment operator (defaults to `:=`)

define FN__EVAL__DEFINE_MACRO
$(1) $(if $(3),$(3),:=) $(2)

endef


## Function:
# FN__DEFINE_ON_FIRST_USE
#     Define macro at time of first use. This is a kind of best of both worlds
#     Makefile optimization. GNU Make has two types of macro assignments:
#         * Classic "deferred" macro assignment, inherited from POSIX Makefiles
#               get expanded at each use. This can be helpful as it often minimizes
#               reliance on declaration order. Also, from an efficiency standpoint,
#               they are only expanded when they are used.
#         * "immediate" macro assignment (added by GNU Make) is only evaluated once,
#               at the point they are declared. These have similarly opposite performance
#               benefits: While they are only ever evaluated once, they *ARE* evaluated
#               even when unused, and are more sensitive to declaration order.
#     FN__DEFINE_ON_FIRST_USE uses FN__EVAL__DEFINE_MACRO to not evaluate a macro until
#     its first use, but then caches the value into an immediate assignment macro at that
#     point, so it is only evaluated once.
#
#     This is most helpful when variable expansion is expensive, like when requiring an
#     external program/shell invocation to evaluate.
#
#     This was mostly inspired by this article:
#         https://www.cmcrossroads.com/article/makefile-optimization-eval-and-macro-caching
#   PARAMETERS:
#     1: The name of the new macro to define
#     2: The new macro's value
#
# MAKEFILE SYNTAX NOTE:
#
# While a trailing backslash at the end of a line normally just causes the following
# line to be considered a continuation of the current line, preceeding the trailing
# backslash with a dollar sign causes the dollar sign, backslash, newline and all
# leading whitespace on the next line to be interperted as the two characters `$ `,
# which expands the undefined "space character" macro to the empty string; resulting
# in a visual linebreak without adding any whitespace.
#
# Please see "3.1.1 Splitting Long Lines: Splitting Without Adding Whitespace"
# in the GNU Make manual.

FN__DEFINE_ON_FIRST_USE = $\
	$(eval \
		$(call \
			FN__EVAL__DEFINE_MACRO,$\
			$(1),$\
			$(if $\
				$($(1)___CACHED_DEFINED),$\
				,$\
				$(eval \
					$(call FN__EVAL__DEFINE_MACRO,$(1)___CACHED_DEFINED,1) \
					$(call FN__EVAL__DEFINE_MACRO,$(1)___CACHED_VALUE,$(2))\
				)$\
			)$($(1)___CACHED_VALUE),$\
			=$\
		)\
	)

## Functions:
# FN__SH__BUILTIN_FRIENDLY_WHICH
# FN__BUILTIN_FRIENDLY_WHICH
#     Resolves a command to a path only if it resolves to an executable
#     file. If the command isn't defined, it resolves to the empty string.
#     Otherwise (if it's a function, alias or builtin) it returns the
#     unmodified command name. This allows reproducing execution of a
#     command from the build output that might have a different PATH than
#     the shell of the Makefile.
#   PARAMETERS:
#     1: The command to resolve
FN__SH__BUILTIN_FRIENDLY_WHICH = $\
    cmd_path="$(DOLLARS)(which "$(1)")" && $\
        if [ -x "$(DOLLARS)cmd_path" ] ; then $\
            echo "$(DOLLARS)cmd_path" ; $\
        else $\
            echo "$(1)"; $\
        fi
FN__BUILTIN_FRIENDLY_WHICH     = $(shell $(call FN__SH__BUILTIN_FRIENDLY_WHICH,$(1)))

### Binaries we use:
$(call FN__DEFINE_ON_FIRST_USE,CAT,$(call            FN__BUILTIN_FRIENDLY_WHICH,cat))
$(call FN__DEFINE_ON_FIRST_USE,RM,$(call             FN__BUILTIN_FRIENDLY_WHICH,rm))
$(call FN__DEFINE_ON_FIRST_USE,MV,$(call             FN__BUILTIN_FRIENDLY_WHICH,mv))
$(call FN__DEFINE_ON_FIRST_USE,MKDIR,$(call          FN__BUILTIN_FRIENDLY_WHICH,mkdir))
$(call FN__DEFINE_ON_FIRST_USE,ECHO,$(call           FN__BUILTIN_FRIENDLY_WHICH,echo))
$(call FN__DEFINE_ON_FIRST_USE,TEE,$(call            FN__BUILTIN_FRIENDLY_WHICH,tee))
$(call FN__DEFINE_ON_FIRST_USE,CAT,$(call            FN__BUILTIN_FRIENDLY_WHICH,cat))
# $(call FN__DEFINE_ON_FIRST_USE,FIND,$(call           FN__BUILTIN_FRIENDLY_WHICH,find))
$(call FN__DEFINE_ON_FIRST_USE,GIT,$(call            FN__BUILTIN_FRIENDLY_WHICH,git))
$(call FN__DEFINE_ON_FIRST_USE,CURL,$(call           FN__BUILTIN_FRIENDLY_WHICH,curl))
$(call FN__DEFINE_ON_FIRST_USE,WGET,$(call           FN__BUILTIN_FRIENDLY_WHICH,wget))
# $(call FN__DEFINE_ON_FIRST_USE,DOCKER,$(call         FN__BUILTIN_FRIENDLY_WHICH,docker))
# $(call FN__DEFINE_ON_FIRST_USE,DOCKER_COMPOSE,$(call FN__BUILTIN_FRIENDLY_WHICH,docker-compose))

# $(SHELL) will usually be either of these two
$(call FN__DEFINE_ON_FIRST_USE,BOURNE_SHELL,$(call   FN__BUILTIN_FRIENDLY_WHICH,sh))
$(call FN__DEFINE_ON_FIRST_USE,BASH_SHELL,$(call     FN__BUILTIN_FRIENDLY_WHICH,bash))

### Project paths:
DEPS_DIR                    = $(PROJECT_BASE_PATH)/deps

### Install paths for ShellSpec:
SHELLSPEC_BASE_INSTALL_DIR  = $(DEPS_DIR)/shellspec
SHELLSPEC_BIN_DIR           = $(SHELLSPEC_BASE_INSTALL_DIR)/bin
SHELLSPEC_INSTALL_DIR       = $(SHELLSPEC_BASE_INSTALL_DIR)/lib
SHELLSPEC_INSTALLER_URL     = https://git.io/shellspec
SHELLSPEC_VERSION_FILE      = $(DEPS_DIR)/shellspec.ver_lock
$(call FN__DEFINE_ON_FIRST_USE,SHELLSPEC_VERSION,$(shell $(CAT) $(SHELLSPEC_VERSION_FILE)))
SHELLSPEC                   = $(SHELLSPEC_BIN_DIR)/shellspec
SHELLSPEC_OPTIONS           = --color
SHELLSPEC_OUTPUT_DIR        = $(PROJECT_BASE_PATH)/output
SHELLSPEC_REPORT_DIR        = $(PROJECT_BASE_PATH)/report
SHELLSPEC_COVERAGE_DIR      = $(PROJECT_BASE_PATH)/coverage
SHELLSPEC_SUCCESS_LOGFILE   = $(SHELLSPEC_OUTPUT_DIR)/shellspec_success.log
SHELLSPEC_FAILURE_LOGFILE   = $(SHELLSPEC_OUTPUT_DIR)/shellspec_failure.log
SHELLSPEC_ALL_LOGFILES      = $(SHELLSPEC_SUCCESS_LOGFILE) $(SHELLSPEC_FAILURE_LOGFILE)

# DOWNLOAD_URL_TO_STDOUT autodetects the presence of `curl` or `wget` and
# produces the correct options to output the contents of the file at the
# provided URL to stdout:
$(call FN__DEFINE_ON_FIRST_USE,DOWNLOAD_URL_TO_STDOUT,$(if $(CURL),$(CURL) -fsSL,$(if $(WGET),$(WGET) -O-,)))


## Functions:
# FN__SH__ESCAPE_FOR_SQUOTES -- for single quotes
# FN__SH__ESCAPE_FOR_DQUOTES -- for double quotes
#     Expand the input string to be properly escaped to be used inside single or
#     double quotes within a shell expression. (Neither the leading nor trailing
#     quotes are generated.)
#   PARAMETERS:
#     1: The string to escape

FN__SH__ESCAPE_FOR_SQUOTES = $(subst ','\'',$(1))
FN__SH__ESCAPE_FOR_DQUOTES = $(subst ",\",$(subst $(DOLLARS),\$(DOLLARS),$(1)))

## Function:
# FN__IS_ABSOLUTE_PATH
# FN__IS_RELATIVE_PATH
#     Does the argument start with a `/`? Result is non-empty when true
#   PARAMETERS:
#     1: The path

FN__IS_ABSOLUTE_PATH = $(if $(patsubst /%,,$(1)),,ABSOLUTE)
FN__IS_RELATIVE_PATH = $(if $(patsubst /%,,$(1)),RELATIVE,)

## Function:
# FN__LIST_PATH_ANCESTORS
#     For any pathname, if it does not contain a `/`, return an empty list,
#     paths that contain it.
#
#     ie. for `foo/bar/baz/bat/bop` return the list: `foo` `foo/bar` `foo/bar/baz` `foo/bar/baz/bat`
#   PARAMETERS:
#     1: The pathname to deconstruct

FN__LIST_PATH_ANCESTORS = $(shell \
	parents=""; \
	for part in "$(subst /," ",$(call FN__SH__ESCAPE_FOR_DQUOTES,$(patsubst /%,%,$(1))))" ; do \
		echo -n "$(DOLLARS)parents" ; \
		if [ "$(DOLLARS)parents" != "" ] ; then \
			echo -n " " ; \
			$(if $(call FN__IS_RELATIVE_PATH,$(1)),parents="$(DOLLARS){parents}/" ; ,) \
		fi ; \
		$(if $(call FN__IS_ABSOLUTE_PATH,$(1)),parents="$(DOLLARS){parents}/" ; ,) \
		parents="$(DOLLARS){parents}$(DOLLARS){part}" ; \
	done ; \
	echo)


## Function:
# FN__DEDUPLICATE_CONTAINING_FILE_LIST
#     In theory, this is similar to $(sort ...), as it removes duplicates, but
#     it also detects files existing within given directories, and removes them
#     (as the specifying the directory is presumed to include its contents.)
#   PARAMETERS:
#     1: The list of file/directory names to minimize

FN__DEDUPLICATE_CONTAINING_FILE_LIST = $\
	$(sort \
		$(foreach \
			path,\
			$(1),\
			$(if \
				$(filter \
					$(call FN__LIST_PATH_ANCESTORS,$(path)),\
					$(1)\
				),\
				,\
				$(path)\
			)\
		)\
	)

## Function:
# FN__SH__RUN_CMD_IN_SPECIFIED_SHELL
#     Based on the enclosing shell (defaults to $(SHELL)) and desired shell,
#     run the specified command in the desired shell (if enclosing and desired)
#     shell match, the command is run directly.
#   PARAMETERS:
#     1: The command to run
#     2: The desired target shell
#     3: The enclosing shell (defaults to $(SHELL))

FN__SH__RUN_CMD_IN_SPECIFIED_SHELL  = \
	$(if \
		$(filter \
			$(firstword $(3) $(SHELL)),\
			$(2)\
		),$\
		$(1),$\
		$(2) -c '$(call FN__SH__ESCAPE_FOR_SQUOTES,$(1))'$\
	)

## Function:
# FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND
#     Force the first failing command in a pipeline to treat the whole pipeline
#     to report failure, by using Bash's "pipefail" option. As this option is only
#     available in bash, the pipeline command is forced to run in bash via
#     FN__SH__RUN_CMD_IN_SPECIFIED_SHELL.
#   PARAMETERS:
#     1: The pipeline command to run
#     2: The enclosing shell (defaults to $(SHELL))

FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND = $(call FN__SH__RUN_CMD_IN_SPECIFIED_SHELL,set -o pipefail ; $(1),$(BASH_SHELL),$(2))

## Functions:
# FN__SH__ECHO_THEN_EXECUTE
# FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE
#     Echo a command to stderr before executing it, similar to the default way make
#     executes recipe lines already. This is helpful if the intended recipe lines are
#     either conditional or executed in a loop, where this conditional or iterative
#     logic would make the intent of the commands less clear. This is intended to be
#     used with a $(SILENCE_WHEN_NOT_VERBOSE) (or @) line prefix so the actual
#     looping or conditional logic is hidden from the user.
#
#     The trivial case of "if condition is true, execute command" is implemented as
#     FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE
#
#     For uniform operation, the `make -s` "silent" option (detected as
#     $(SILENT_MODE) above) will automatically turn off the echoing when present
#     unless `ALWAYS_ECHO` is specified as the last argument. Any other non-empty
#     final argument unconditionally disables the echoing.
#   PARAMETERS:
#     FN__SH__ECHO_THEN_EXECUTE:
#         1: The command to run
#         2: Silence echoing; intended to be one of:
#             * ALWAYS_ECHO
#             * NEVER_ECHO
#             * $(SILENT_MODE) (default)
#     FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE:
#         1: The condition specifying if the command should be run
#         2: The command to run
#         3: Silence echoing; intended to be one of:
#             * ALWAYS_ECHO
#             * NEVER_ECHO
#             * $(SILENT_MODE) (default)

FN__SH__ECHO_THEN_EXECUTE              = \
	$(if \
		$(filter-out \
			ALWAYS_ECHO,\
			$(firstword $(2) $(SILENT_MODE))\
		),$\
		,$\
		>&2 $(ECHO) '$(call FN__SH__ESCAPE_FOR_SQUOTES,$(1))' ; $\
	)$(1)
FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE = if $(1) ; then $(call FN__SH__ECHO_THEN_EXECUTE,$(2),$(3)) ; fi

SHELLSPEC_OUTPUT_DIRS = $(SHELLSPEC_OUTPUT_DIR) $(SHELLSPEC_REPORT_DIR) $(SHELLSPEC_COVERAGE_DIR)

GENERATED_DIRS        = $(SHELLSPEC_OUTPUT_DIRS)

GENERATED             = $(SHELLSPEC_ALL_LOGFILES) $(GENERATED_DIRS)

DOWNLOADED            = $(SHELLSPEC_BASE_INSTALL_DIR)


## Function:
# FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE
#     Generate the Makefile rule to run ShellSpec, so the forced and unforced
#     rules can share the same recipe can share the same code.
#     The only difference between the two rules is the target name, and one
#     additional dependancy: "FORCE"
#
#     We use FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND to detect an error when running
#     our tests, even though we `tee` them into a log file. If we fail, we rename
#     the log $(SHELLSPEC_FAILURE_LOGFILE) so make knows the tests have not run
#     successfully.
#   PARAMETERS:
#     1: The target name
#     2: Any additional dependancies

define FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE

$(1): $(SHELLSPEC) $(SHELLSPEC_OUTPUT_DIRS) $(2) \
                         $(wildcard spec/*_spec.sh) \
                         $(wildcard spec/*_helper.sh) \
      $(foreach dep_file,$(wildcard spec/*_spec.deps),$(shell $(CAT) $(dep_file)))
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -f "$(SHELLSPEC_FAILURE_LOGFILE)" ],$\
		$(RM) -f "$(SHELLSPEC_FAILURE_LOGFILE)"$\
	)
	$(call FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND,$\
		($(SHELLSPEC) $(SHELLSPEC_OPTIONS) | $(TEE) $(SHELLSPEC_SUCCESS_LOGFILE)) || $\
		($(MV) $(SHELLSPEC_SUCCESS_LOGFILE) $(SHELLSPEC_FAILURE_LOGFILE) ; exit 1) $\
	)


endef

## Function:
# FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE
#     Generate the Makefile rule to create an empty directory so these can
#     all be generated in a loop.
#   PARAMETERS:
#     1: The the name of the directory

define FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE


$(1):
	$(SILENCE_WHEN_NOT_VERBOSE)$(call FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,! [ -d "$(1)" ],$(MKDIR) -p $(1))


endef

all: test_cachable

# This is (in theory) a list of all Makefile targets that don't correspond
# to filesystem files. In reality `FORCE` is not included in this list as
# we rely on it being a perpetually missing file.
.PHONY: all test test_cachable test_force clean dist_clean dev_containers verbose

test: test_force

test_cachable: $(SHELLSPEC_SUCCESS_LOGFILE)


$(eval \
        $(call FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE,$(SHELLSPEC_SUCCESS_LOGFILE),) \
        $(call FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE,test_force,FORCE) \
        $(foreach dir_name,$(GENERATED_DIRS),$(call FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE,$(dir_name))))


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
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -e "$(SHELLSPEC_BASE_INSTALL_DIR)" ],$\
		$(RM) -rf "$(SHELLSPEC_BASE_INSTALL_DIR)"\
	)
	$(call FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND,$\
		$(DOWNLOAD_URL_TO_STDOUT) $(SHELLSPEC_INSTALLER_URL) | $\
			$(BOURNE_SHELL) $\
				-s $(SHELLSPEC_VERSION) $\
				--bin "$(SHELLSPEC_BIN_DIR)" $\
				--dir "$(SHELLSPEC_INSTALL_DIR)" $\
				--yes $\
	)

clean: FORCE
	rm -rf $(call FN__DEDUPLICATE_CONTAINING_FILE_LIST,$(GENERATED))

dist_clean: FORCE
	rm -rf $(call FN__DEDUPLICATE_CONTAINING_FILE_LIST,$(GENERATED) $(DOWNLOADED))


# Dummy target, to put makefile into verbose mode.
# The dependancy expands to "all" there are no explicit goals besides
# "verbose"
# See $(VERBOSE_MODE) above.
verbose: $(if $(filter-out verbose,$(MAKECMDGOALS)),,all)

FORCE:


