## This project currently requires GNU Make.

# While it would be nice if we supported a lowest common denominator POSIX make,
# we are using too many advanced features to do this reasonably at this time.

### Project paths:
PROJECT_BASE_PATH                   := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

PROJECT_PREFERED_COMMAND_RESOLUTION := FN__PREFER_EXECUTABLE_FILE_WHICH
# Added to list of `.` and `..` to remove from directory search results
# using FN__FIND_SUBDIRS_IN and FN__SEARCH_DIR_FOR_PATTERN.
SPECIAL_DIRS_TO_IGNORE              := .git


include $(PROJECT_BASE_PATH)/func_lib.mk

### Binaries we use:
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,cat)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,cut)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,curl)
# $(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,find)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,git)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,mv)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,rm)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,tail)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,tee)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,wget)

### Project paths:
DEPS_DIR                    = $(PROJECT_BASE_PATH)/deps
OUTPUT_LOGS_DIR             = $(PROJECT_BASE_PATH)/output

### Install paths for ShellSpec:
SHELLSPEC_BASE_INSTALL_DIR  = $(DEPS_DIR)/shellspec
SHELLSPEC_BIN_DIR           = $(SHELLSPEC_BASE_INSTALL_DIR)/bin
SHELLSPEC_INSTALL_DIR       = $(SHELLSPEC_BASE_INSTALL_DIR)/lib
SHELLSPEC_INSTALLER_URL     = https://git.io/shellspec
SHELLSPEC_VERSION_FILE      = $(DEPS_DIR)/shellspec.ver_lock
$(call FN__DEFINE_ON_FIRST_USE,SHELLSPEC_VERSION,$(DOLLARS)$(OPEN_PAREN)call FN__DEBUGABLE_SUBSHELL$(COMMA)$(DOLLARS)$(OPEN_PAREN)CAT$(CLOSE_PAREN) $(SHELLSPEC_VERSION_FILE)$(CLOSE_PAREN))
SHELLSPEC                   = $(call FN__SIMPLIFY_EXECUTABLE_PATHS,$(SHELLSPEC_BIN_DIR)/shellspec)
SHELLSPEC_PATH              = $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_BIN_DIR)/shellspec)
SHELLSPEC_OPTIONS           = --color
SHELLSPEC_REPORT_DIR        = $(PROJECT_BASE_PATH)/report
SHELLSPEC_COVERAGE_DIR      = $(PROJECT_BASE_PATH)/coverage

# DOWNLOAD_URL_TO_STDOUT autodetects the presence of `curl` or `wget` and
# produces the correct options to output the contents of the file at the
# provided URL to stdout. (DOWNLOAD_URL_TO_STDOUT_PATH just the path of the binary)
# NOTE: Using `_PATH` variant of macro to prevent duplicate `$(error ...)` race
# condition.
DOWNLOAD_URL_TO_STDOUT_PATH = $(if $(CURL_PATH),$(CURL_PATH),$(WGET_PATH))
DOWNLOAD_URL_TO_STDOUT      = \
	$(call \
		FN__VERIFY_COMMAND_PRESENT_WITH_CUSTOM_ERROR_MESSAGE,$\
		DOWNLOAD_URL_TO_STDOUT,$\
		Either curl or wget must be installed to install ShellSpec via https. $\
			Neither binary found in current PATH.$\
	)$(if \
		$(CURL_PATH),$\
		$(call FN__SIMPLIFY_EXECUTABLE_PATHS,$(CURL_PATH)) -fsSL,$\
		$(if $(WGET_PATH),$(call FN__SIMPLIFY_EXECUTABLE_PATHS,$(WGET_PATH)) -O-,)$\
	)

## Docker setup:
# Like most other commands, we use FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE
# so an error message is forced if we attempt to run docker when it's not installed

# In addition to verifying the existance of the executables, we have some additional
# preparation we want to do. As with the other command verification, we ensure they
# are only done when the current invocation of Make is going to actually use docker

# To do this we make the docker and docker-compose actually defined as DOCKER__INTERNAL
# and DOCKER_COMPOSE__INTERNAL respectively and proxy to these from aliases.

# As the _PATH macros aren't intended to do any additional validation, they are proxied
# directly, with no fancy define-on-use mechanism

# The DOCKER and DOCKER_COMPOSE macros both expand $(DOCKER_PREMAKERUN_INITIALIZED)
# which initiates our docker startup/validation code:

# First we need to insure the docker daemon is running so that docker is
# ready to use. (This will normally require a sudo, so it isn't worth attempting to
# start it ourselves.)

# Secondly we want to store the state of any running and non-running containers so
# we can restore this state after non-destructive operations (like running the test
# suite). In this case we can delete any containers created exclusively for the
# non-destructive operations and shut down any containers started under the same
# circumstances.

# Additionally, the routine to capture the docker container state is generalized into
# a repeatable function with $(call FN__EVAL__CAPTURE_DOCKER_SYSTEM_STATUS,snapshot_name)
# so snapshots from different points of time can be compared.


DOCKER_CONTAINER_PROPERTIES = Command CreatedAt ID Image Labels LocalVolumes Mounts Names Networks Ports RunningFor Size State Status
DOCKER_IMAGE_PROPERTIES     = Containers CreatedAt CreatedSince Digest ID Repository SharedSize Size Tag UniqueSize VirtualSize
DOCKER_VOLUME_PROPERTIES    = Driver Labels Links Mountpoint Name Scope Size

$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,docker,DOCKER__INTERNAL)
$(call \
	FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,$\
	docker-compose,$\
	DOCKER_COMPOSE__INTERNAL,$\
	Docker Compose,$\
	Docker must be installed. docker-compose binary not found in current PATH.$\
)
DOCKER_PATH         = $(DOCKER__INTERNAL_PATH)
DOCKER_COMPOSE_PATH = $(DOCKER_COMPOSE__INTERNAL_PATH)

FN__DOCKER_OBJECT_STATUS_TEMPLATE = \
	DOCKER_$(1)_$(2)_UC_IDS += $(3)@@EOL@@ $\
	$(foreach \
		each_prop,$\
		$(DOCKER_$(2)_PROPERTIES),$\
		DOCKER_$(1)_$(2)__$(3)__$(call \
			FN__TO_UPPER_SNAKE_CASE,$\
			$(each_prop)$\
		) = {{.$(each_prop)}}@@EOL@@$\
	)

FN__EVAL__CAPTURE_DOCKER_OBJECT_STATUS = \
	$(DOLLARS)$(OPEN_PAREN)DOCKER__INTERNAL$(CLOSE_PAREN) $\
		$(4) --format '$(call \
			FN__DOCKER_OBJECT_STATUS_TEMPLATE,$\
			$(1),$\
			$(2),$\
			$(3)$\
		)'

FN__EVAL__CAPTURE_DOCKER_SYSTEM_STATUS = \
	$(DOLLARS)$(OPEN_PAREN)call \
		FN__DEBUGABLE_EVAL$(COMMA)$\
		$(DOLLARS)$(OPEN_PAREN)subst \
			@@EOL@@$(COMMA)$\
			$(DOLLARS)$(OPEN_PAREN)NEWLINE$(CLOSE_PAREN)$(COMMA)$\
			$(DOLLARS)$(OPEN_PAREN)subst \
				@@EOL@@$(DOLLARS)$(OPEN_PAREN)SPACE$(CLOSE_PAREN)$(COMMA)$\
				@@EOL@@$(COMMA)$\
				$(DOLLARS)$(OPEN_PAREN)call \
					FN__DEBUGABLE_SUBSHELL$(COMMA)$\
					$(call \
						FN__EVAL__CAPTURE_DOCKER_OBJECT_STATUS,$\
						$(1),$\
						CONTAINER,$\
						{{upper .ID}},$\
						ps --all$\
					) ; $\
					$(call \
						FN__EVAL__CAPTURE_DOCKER_OBJECT_STATUS,$\
						$(1),$\
						IMAGE,$\
						{{upper .ID}},$\
						images ls --all$\
					) ; $\
					$(call \
						FN__EVAL__CAPTURE_DOCKER_OBJECT_STATUS,$\
						$(1),$\
						VOLUME,$\
						$(DOLLARS)$(OPEN_PAREN)DOLLARS$(CLOSE_PAREN)$(DOLLARS)$(OPEN_PAREN)OPEN_PAREN$(CLOSE_PAREN)call \
							FN__TO_UPPER_SNAKE_CASE$(DOLLARS)$(OPEN_PAREN)COMMA$(CLOSE_PAREN)$\
							{{.Name}}$\
						$(DOLLARS)$(OPEN_PAREN)CLOSE_PAREN$(CLOSE_PAREN),$\
						volume ls$\
					)$\
				$(CLOSE_PAREN)$\
			$(CLOSE_PAREN)$\
		$(CLOSE_PAREN)$\
	$(CLOSE_PAREN)

EVAL__INIT_PREMAKERUN_DOCKER_STATUS = \
	$(DOLLARS)$(OPEN_PAREN)if \
		$(DOLLARS)$(OPEN_PAREN)call \
			FN__DEBUGABLE_SUBSHELL$(COMMA)$\
			$(DOLLARS)$(OPEN_PAREN)DOCKER__INTERNAL$(CLOSE_PAREN) $\
				info > /dev/null 2> /dev/null && $\
			echo "Docker ok"$\
		$(CLOSE_PAREN)$(COMMA)$\
		$(call \
			FN__EVAL__CAPTURE_DOCKER_SYSTEM_STATUS,$\
			PREMAKERUN$\
		)$(COMMA)$\
		$(DOLLARS)$(OPEN_PAREN)error \
			Unable to obtain status info from Docker daemon. $\
			Please ensure Docker is properly installed and running.$\
		$(CLOSE_PAREN)$\
	$(CLOSE_PAREN)$\
	$(DOLLARS)$(OPEN_PAREN)if \
		$(DOLLARS)$(OPEN_PAREN)DOCKER_COMPOSE__INTERNAL$(CLOSE_PAREN)$(COMMA)$\
		$(COMMA)$\
		$\
	$(CLOSE_PAREN)


$(call \
	FN__DEFINE_ON_FIRST_USE,$\
	DOCKER_PREMAKERUN_INITIALIZED,$\
	$(DOLLARS)$(OPEN_PAREN)call \
		FN__DEBUGABLE_EVAL$(COMMA)$\
		$(DOLLARS)$(OPEN_PAREN)EVAL__INIT_PREMAKERUN_DOCKER_STATUS$(CLOSE_PAREN)$\
	$(CLOSE_PAREN)TRUE$\
)

DOCKER = \
	$(if \
		$(DOCKER_PREMAKERUN_INITIALIZED),$\
		$(DOCKER__INTERNAL),$\
		$(error Unreachable!)$\
	)
DOCKER_COMPOSE = \
	$(if \
		$(DOCKER_PREMAKERUN_INITIALIZED),$\
		$(DOCKER_COMPOSE__INTERNAL),$\
		$(error Unreachable!)$\
	)

include $(PROJECT_BASE_PATH)/project_info.mk

OPERATIONS_STATUSES = success failure
ALL_TEST_SUITES     = \
	shellspec $\
	$(foreach \
		ea_comp,$\
		$(PROJECT_DOCKER_COMPOSITION_NAMES),$\
		$(foreach \
			ea_cont,$\
			$(PROJECT__$(ea_comp)__CONTAINER_LABELS),$\
			$(foreach \
				ea_suite,$\
				$(PROJECT__$(ea_comp)__$(ea_cont)__TEST_SUITES),$\
				$(call \
					FN__TO_CAMEL_CASE,$\
					$(ea_comp)$\
				)_$(call \
					FN__TO_CAMEL_CASE,$\
					$(ea_cont)$\
				)_$(call \
					FN__TO_CAMEL_CASE,$\
					$(ea_suite)$\
				)$\
			)$\
		)$\
	)

FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES = \
	$(foreach \
		ea_suite,$\
		$(1),$\
		$(foreach \
			ea_status,$\
			$(2),$\
			$(OUTPUT_LOGS_DIR)/$(ea_suite)_$(ea_status).log$\
		)$\
	)

ALL_TEST_SUITE_LOGFILES = \
	$(call \
		FN_TEST_LOGFILES_FOR_STATUSES_AND_SUITES,$\
		$(ALL_TEST_SUITES),$\
		$(OPERATIONS_STATUSES)$\
	)

SHELLSPEC_OUTPUT_DIRS = $(SHELLSPEC_REPORT_DIR) $(SHELLSPEC_COVERAGE_DIR)

GENERATED_DIRS        = $(OUTPUT_LOGS_DIR) $(SHELLSPEC_OUTPUT_DIRS)

GENERATED             = $(ALL_TEST_SUITE_LOGFILES) $(GENERATED_DIRS)

DOWNLOADED            = $(SHELLSPEC_BASE_INSTALL_DIR)


## Function:
# FN__EVAL__GENERATE_SINGLE_GENERIC_TESTS_RULE
#     Generate the Makefile rule to run test suite, so the rule variations can
#     have a single source.
#
#     We use FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND to detect an error when running
#     our tests, even though we `tee` them into a failure log file. If we succeed,
#     we rename the log to a success file, so the success file only exists if the
#     tests ran to completion.
#   PARAMETERS:
#     1: The test suite name
#     2: The target name
#     3: All primary dependancies
#     4: All dependancy files (the files contents contains a list of dependancies)
#     5: The command to run to launch the test suite

define FN__EVAL__GENERATE_SINGLE_GENERIC_TESTS_RULE

$(2): $(call \
	FN__SIMPLIFY_PATHS,$\
	$(3) $(OUTPUT_LOGS_DIR) $(foreach \
		dep_file,$\
		$(4),$\
		$(dep_file) $(call \
			FN__DEBUGABLE_SUBSHELL,$\
			$(CAT) $(dep_file)$\
		)$\
	)$\
)
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -f "$(call \
			FN__SIMPLIFY_PATHS,$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(1),$\
				failure$\
			)$\
		)" ],$\
		$(RM) -f "$(call \
			FN__SIMPLIFY_PATHS,$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(1),$\
				failure$\
			)$\
		)"$\
	)
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -f "$(call \
			FN__SIMPLIFY_PATHS,$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(1),$\
				success$\
			)$\
		)" ],$\
		$(RM) -f "$(call \
			FN__SIMPLIFY_PATHS,$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(1),$\
				success$\
			)$\
		)"$\
	)
	$(call FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND,$\
		$(OPEN_PAREN)$\
			$(5) | $(TEE) $(call \
				FN__SIMPLIFY_PATHS,$\
				$(call \
					FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
					$(1),$\
					failure$\
				)$\
			)$\
		$(CLOSE_PAREN) && $(OPEN_PAREN)$\
			$(MV) $(call \
				FN__SIMPLIFY_PATHS,$\
				$(call \
					FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
					$(1),$\
					failure$\
				)$\
			) $(call \
				FN__SIMPLIFY_PATHS,$\
				$(call \
					FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
					$(1),$\
					success$\
				)$\
			)$\
		$(CLOSE_PAREN) $\
	)


endef


## Function:
# FN__EVAL__GENERATE_GENERIC_TESTS_RULE_PAIR
#     Generate pair of Makefile rules to run a generic test suite. The rule details
#     are defined in FN__EVAL__GENERATE_SINGLE_GENERIC_TESTS_RULE so the forced and
#     unforced rules can share the same recipe code. The only difference between
#     the two rules is the target name, and one additional dependancy: "FORCE"
#   PARAMETERS:
#     1: The test suite name
#     2: All primary dependancies
#     3: All dependancy files (the files contents contains a list of dependancies)
#     4: The command to run to launch the test suite

FN__EVAL__GENERATE_GENERIC_TESTS_RULE_PAIR = \
	$(call \
		FN__EVAL__GENERATE_SINGLE_GENERIC_TESTS_RULE,$\
		$(1),$\
		$(call \
			FN__SIMPLIFY_PATHS,$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(1),$\
				success$\
			)),$\
		$(2),$\
		$(3),$\
		$(4)$\
	) $\
	$(call \
		FN__EVAL__GENERATE_SINGLE_GENERIC_TESTS_RULE,$\
		$(1),$\
		test_$(1)_force,$\
		$(2) FORCE,$\
		$(3),$\
		$(4)$\
	)


ALL_TEST_SUITE_LOGFILES = \
	$(foreach \
		ea_suite,$\
		$(ALL_TEST_SUITES),$\
		$(foreach \
			ea_status,$\
			$(OPERATIONS_STATUSES),$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(ea_suite),$\
				$(ea_status)$\
			)$\
		)$\
	)

all default: test_cachable

# This is (in theory) a list of all Makefile targets that don't correspond
# to filesystem files.
.PHONY: all default test test_cachable test_force clean dist_clean dev_containers \
	$(foreach ea_suite,$(ALL_TEST_SUITES),test_$(ea_suite)_force) $(FUNC_LIB_PHONY_TARGETS)

test: test_force

test_cachable: $(call \
		FN__SIMPLIFY_PATHS,$\
		$(foreach \
			ea_suite,$\
			$(ALL_TEST_SUITES),$\
			$(call \
				FN_TEST_LOGFILES_FOR_SUITES_AND_STATUSES,$\
				$(ea_suite),$\
				success$\
			)$\
		)$\
	)

test_force: $(foreach ea_suite,$(ALL_TEST_SUITES),test_$(ea_suite)_force)


$(call \
	FN__DEBUGABLE_EVAL,$\
	$(call \
		FN__EVAL__GENERATE_GENERIC_TESTS_RULE_PAIR,$\
		shellspec,$\
		$(SHELLSPEC) $(SHELLSPEC_OUTPUT_DIRS) $\
			$(wildcard spec/*_spec.sh) $(wildcard spec/*_helper.sh),$\
		$(wildcard spec/*_spec.deps),$\
		$(SHELLSPEC) $(SHELLSPEC_OPTIONS)$\
	) $\
	$(foreach \
		ea_comp,$\
		$(PROJECT_DOCKER_COMPOSITION_NAMES),$\
		$(foreach \
			ea_cont,$\
			$(PROJECT__$(ea_comp)__CONTAINER_LABELS),$\
			$(foreach \
				ea_suite,$\
				$(PROJECT__$(ea_comp)__$(ea_cont)__TEST_SUITES),$\
				$(call \
					FN__EVAL__GENERATE_GENERIC_TESTS_RULE_PAIR,$\
					$(call \
						FN__TO_CAMEL_CASE,$\
						$(ea_comp)$\
					)_$(call \
						FN__TO_CAMEL_CASE,$\
						$(ea_cont)$\
					)_$(call \
						FN__TO_CAMEL_CASE,$\
						$(ea_suite)$\
					),$\
					$(call \
						FN__SIMPLIFY_PATHS,$\
						$(call \
							FN__SEARCH_DIR_FOR_PATTERN,$\
							$(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__PROJECT_DIR),$\
							*,$\
							$\
						)$\
					),$\
					$(wildcard $(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__PROJECT_DIR)/*.deps), $\
					$(DOLLARS)$(OPEN_PAREN)DOCKER_COMPOSE$(CLOSE_PAREN) $\
						$(if \
							$(PROJECT__$(ea_comp)__DOCKER_COMPOSE_FILE),$\
							$(if \
								$(filter 1,$(words $(PROJECT__$(ea_comp)__DOCKER_COMPOSE_FILE))),$\
								,$\
								$(error Docker composition $(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_comp)$\
								) is only allowed one docker-compose file.)$\
							)--file $(call \
								FN__SIMPLIFY_PATHS,$\
								$(PROJECT__$(ea_comp)__DOCKER_COMPOSE_FILE)$\
							)$(SPACE),$\
							$\
						)$\
						run --rm $(PROJECT__$(ea_comp)__$(ea_suite)__NAME) $\
						$(if \
							$(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_DIR),$\
							$(if \
								$(filter 1,$(words $(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_DIR))),$\
								,$\
								$(error Test suite $(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_comp)$\
								)_$(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_cont)$\
								)_$(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_suite)$\
								) is only allowed one working direcory)$\
							)--workdir $(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_DIR)$(SPACE),$\
							$\
						)$\
						$(if \
							$(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_USER),$\
							$(if \
								$(filter 1,$(words $(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_USER))),$\
								,$\
								$(error Test suite $(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_comp)$\
								)_$(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_cont)$\
								)_$(call \
									FN__TO_CAMEL_CASE,$\
									$(ea_suite)$\
								) is only allowed one current user)$\
							)--user $(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_USER)$(SPACE),$\
							$\
						)$\
						$(foreach \
							ea_vol,$\
							$(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__CONTAINER_VOLUMES),$\
							--volume $(ea_vol)$(SPACE)$\
						)$\
						$(PROJECT__$(ea_comp)__$(ea_cont)__$(ea_suite)__LAUNCH_COMMAND)$\
				)$\
			)$\
		)$\
	) $\
	$(foreach \
		dir_name,$\
		$(GENERATED_DIRS),$\
		$(call \
			FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE,$\
			$(dir_name)$\
		)$\
	)$\
)


# dev_containers:
# 	$(SILENCE_WHEN_NOT_VERBOSE)# $(DOCKER_COMPOSE_PATH)


$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_PATH)): $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_VERSION_FILE))
	$(SILENCE_WHEN_NOT_VERBOSE)# $(call \
		FN__VERIFY_COMMAND_PRESENT_WITH_CUSTOM_ERROR_MESSAGE,$\
		GIT,$\
		git must be installed to install ShellSpec. Git binary not found in current PATH.$\
	)
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -e "$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_BASE_INSTALL_DIR))" ],$\
		$(RM) -rf "$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_BASE_INSTALL_DIR))"$\
	)
	$(call FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND,$\
		$(strip $(DOWNLOAD_URL_TO_STDOUT) $(SHELLSPEC_INSTALLER_URL) | $\
			$(POSIX_SHELL) $\
				-s $(SHELLSPEC_VERSION) $\
				--bin "$(SHELLSPEC_BIN_DIR)" $\
				--dir "$(SHELLSPEC_INSTALL_DIR)" $\
				--yes $\
		)$\
	)

clean: FORCE
	rm -rf $(call FN__SIMPLIFY_PATHS,$(call FN__DEDUPLICATE_CONTAINING_FILE_LIST,$(GENERATED)))

dist_clean: FORCE
	rm -rf $(call FN__SIMPLIFY_PATHS,$(call FN__DEDUPLICATE_CONTAINING_FILE_LIST,$(GENERATED) $(DOWNLOADED)))


$(eval $(EVAL__FUNC_LIB_MAKEFILE_FOOTER))


