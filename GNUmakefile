## This project currently requires GNU Make.

# While it would be nice if we supported a lowest common denominator POSIX make,
# we are using too many advanced features to do this reasonably at this time.

### Project paths:
PROJECT_BASE_PATH                   := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

PROJECT_PREFERED_COMMAND_RESOLUTION := FN__PREFER_EXECUTABLE_FILE_WHICH


include $(PROJECT_BASE_PATH)/func_lib.mk

### Binaries we use:
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,cat)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,cut)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,curl)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,docker)
$(call \
	FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,$\
	docker-compose,$\
	DOCKER_COMPOSE,$\
	Docker Compose,$\
	Docker must be installed. docker-compose binary not found in current PATH.$\
)
# $(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,find)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,git)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,mv)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,rm)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,tail)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,tee)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,wget)

### Project paths:
DEPS_DIR                    = $(PROJECT_BASE_PATH)/deps

### Install paths for ShellSpec:
SHELLSPEC_BASE_INSTALL_DIR  = $(DEPS_DIR)/shellspec
SHELLSPEC_BIN_DIR           = $(SHELLSPEC_BASE_INSTALL_DIR)/bin
SHELLSPEC_INSTALL_DIR       = $(SHELLSPEC_BASE_INSTALL_DIR)/lib
SHELLSPEC_INSTALLER_URL     = https://git.io/shellspec
SHELLSPEC_VERSION_FILE      = $(DEPS_DIR)/shellspec.ver_lock
$(call FN__DEFINE_ON_FIRST_USE,SHELLSPEC_VERSION,$(call FN__DEBUGABLE_SUBSHELL,$(CAT) $(SHELLSPEC_VERSION_FILE)))
SHELLSPEC                   = $(call FN__SIMPLIFY_EXECUTABLE_PATHS,$(SHELLSPEC_BIN_DIR)/shellspec)
SHELLSPEC_PATH              = $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_BIN_DIR)/shellspec)
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
# (DOWNLOAD_URL_TO_STDOUT_PATH just the path of the binary)
DOWNLOAD_URL_TO_STDOUT_PATH = $(firstword $(CURL_PATH) $(WGET_PATH))
DOWNLOAD_URL_TO_STDOUT      = $(if $(CURL_PATH),$(CURL) -fsSL,$(if $(WGET_PATH),$(WGET) -O-,))

# include $(PROJECT_BASE_PATH)/project_info.mk


# PROJECT_DOCKER_BASE_DIR_APPS = docker_base:my_app
# FN__EXTRACT_EACH_DOCKER_BASE_RAW_DIR = $\
# 	$(firstword $\
# 		$(subst $\
# 			:,$\
# 			$(SPACE),$\
# 			$(1)$\
# 		)$\
# 	)
# FN__EXTRACT_EACH_DOCKER_APP_RAW_DIR_LIST = $\
# 	$(subst $\
# 		$(COMMA),$\
# 		$(SPACE),$\
# 		$(word $\
# 			2,$\
# 			$(subst $\
# 				:,$\
# 				$(SPACE),$\
# 				$(1)$\
# 			)$\
# 		)$\
# 	)
# FN__PROJ_DOCKER_BASE_DIR = \
# 	$(foreach \
# 		base_dir_apps,$\
# 		$(1),$\
# 		$(PROJECT_BASE_PATH)/$(call FN__EXTRACT_EACH_DOCKER_BASE_RAW_DIR,$(base_dir_apps))$\
# 	)
# FN__PROJ_DOCKER_APP_DIRS = \
# 	$(foreach \
# 		base_dir_apps,$\
# 		$(1),$\
# 		$(foreach \
# 			app_dir,$\
# 			$(call FN__EXTRACT_EACH_DOCKER_APP_RAW_DIR_LIST,$(base_dir_apps)),$\
# 			$(PROJECT_BASE_PATH)/$(call FN__EXTRACT_EACH_DOCKER_BASE_RAW_DIR,$(base_dir_apps))/$(app_dir)$\
# 		)$/
# 	)
# PROJECT_DOCKER_BASE_DIRS = $(PROJECT_BASE_PATH)/docker_base
# FN__PROJECT_APP_DIRS     = \
# 	$(foreach \
# 		docker_base_path,$\
# 		$(1),$\
# 		$(if \
# 			$(filter \
# 				$(PROJECT_BASE_PATH)/docker_base,\
# 				$(docker_base_path)\
# 			),$\
# 			$(PROJECT_BASE_PATH)/docker_base/my_app,$\
# 			$\
# 		)$\
# 	)

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

$(1): $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC) $(SHELLSPEC_OUTPUT_DIRS) $(2) \
                         $(wildcard spec/*_spec.sh) \
                         $(wildcard spec/*_helper.sh) \
      $(foreach dep_file,$(wildcard spec/*_spec.deps),$(call FN__DEBUGABLE_SUBSHELL,$(CAT) $(dep_file))))
	$(SILENCE_WHEN_NOT_VERBOSE)$(call \
		FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,$\
		[ -f "$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_FAILURE_LOGFILE))" ],$\
		$(RM) -f "$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_FAILURE_LOGFILE))"$\
	)
	$(call FN__SH__ENABLE_PIPEFAIL_FOR_COMMAND,$\
		($(SHELLSPEC) $(SHELLSPEC_OPTIONS) | $(TEE) $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_SUCCESS_LOGFILE))) || $\
		($(MV) $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_SUCCESS_LOGFILE)) $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_FAILURE_LOGFILE)) ; exit 1) $\
	)


endef

all default: test_cachable

# This is (in theory) a list of all Makefile targets that don't correspond
# to filesystem files. 
.PHONY: all default test test_cachable test_force clean dist_clean dev_containers $(FUNC_LIB_PHONY_TARGETS)

test: test_force

test_cachable: $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_SUCCESS_LOGFILE))


$(call FN__DEBUGABLE_EVAL,$\
        $(call FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE,$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_SUCCESS_LOGFILE)),) \
        $(call FN__EVAL__GENERATE_SHELLSPEC_TESTS_RULE,test_force,FORCE) \
        $(foreach dir_name,$(GENERATED_DIRS),$(call FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE,$(dir_name))))


dev_containers:
	$(SILENCE_WHEN_NOT_VERBOSE)# $(DOCKER_COMPOSE_PATH)
	$(SILENCE_WHEN_NOT_VERBOSE)($(DOCKER) info > /dev/null 2> /dev/null) ||  \
        >&2 $(ECHO) "Unable to obtain status info from Docker daemon. Please" \
            "ensure Docker is properly installed and running." ; \
        exit 1


$(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_PATH)): $(call FN__SIMPLIFY_PATHS,$(SHELLSPEC_VERSION_FILE))
	$(SILENCE_WHEN_NOT_VERBOSE)# $(call \
		FN__VERIFY_COMMAND_PRESENT_WITH_CUSTOM_ERROR_MESSAGE,$\
		DOWNLOAD_URL_TO_STDOUT,$\
		Either curl or wget must be installed to install ShellSpec via https. Neither binary found in current PATH.$\
	)
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


