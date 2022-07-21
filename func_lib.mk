## Library of general purpose functions for GNU Make.

# As suggested here: https://stackoverflow.com/questions/58367235/how-to-detect-if-the-makefile-silent-quiet-command-line-option-was-set
# Set SILENT to 's' if --quiet/-s set, otherwise ''.
# This allows us to silence command eching when we're doing it manually.
# See FN__SH__ECHO_THEN_EXECUTE.
SILENT_MODE                         := $(findstring s,$(word 1, $(MAKEFLAGS)))

# Here we detect a phony target (used as the antithesis of SILENT_MODE) to
# echo all commands in recipes by removing the `@` at the beginning of recipe
# lines.

# As GNU Make provides no way to do this, we use $(SILENCE_WHEN_NOT_VERBOSE) in
# place of `@` at the beginning of recipe lines, so we can easily remove them.
VERBOSE_MODE                        := $(filter verbose,$(MAKECMDGOALS))
SILENCE_WHEN_NOT_VERBOSE            := $(if $(VERBOSE_MODE),,@)

# VERBOSE_DEBUG_MODEis implemented exactly like VERBOSE_MODE, but instead of showing
# recipe commands that would otherwise be silenced, it shows code executed by
# $(MAKE) in $(eval ...) and $(shell ...) functions.
VERBOSE_DEBUG_MODE                  := $(filter verbose_debug,$(MAKECMDGOALS))


# This is added to the list of Makefile targets that don't correspond
# to filesystem files. In reality `FORCE` is not included in this list as
# we rely on it being a perpetually missing file.
FUNC_LIB_PHONY_TARGETS              := verbose verbose_debug

## Common makefile special-character aliases:
DOLLARS                             := $$
BLANK                               :=
SPACE                               := $(BLANK) $(BLANK)
COMMA                               := ,
HASH                                := \#
BACKSLASH                           := \\
OPEN_PAREN                          := (
CLOSE_PAREN                         := )
OPEN_CURLEY_BRACES                  := {
CLOSE_CURLEY_BRACES                 := }
define NEWLINE


endef


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

UNEXPANDED_NO_WHITESPACE_LINEBREAK := $(DOLLARS)$(SPACE)


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

# FN__DEBUGABLE_EVAL
#     Drop in replacement for `$(eval ...)`. Works identically except echos source to be executed
#     as $(warning ...) when $(VERBOSE_DEBUG_MODE) is non-empty.
#   PARAMETERS:
#     1: Makefile source string to evaluate
FN__DEBUGABLE_EVAL = \
	$(if \
		$(VERBOSE_DEBUG_MODE),$\
		$(warning \
			[Debug output] $(MAKE) about to $(DOLLARS)$(OPEN_PAREN)eval ...$(CLOSE_PAREN):$\
			$(NEWLINE)$\
			$(NEWLINE)$\
			$(1)$\
		),$\
		$\
	)$(eval $(1))

# FN__DEBUGABLE_SUBSHELL
#     Drop in replacement for `$(shell ...)`. Works identically except echos shell source to be executed
#     as $(warning ...) when $(VERBOSE_DEBUG_MODE) is non-empty.
#   PARAMETERS:
#     1: Shell source string to execute
FN__DEBUGABLE_SUBSHELL = \
	$(if \
		$(VERBOSE_DEBUG_MODE),$\
		$(warning \
			[Debug output] $(MAKE) about to $(DOLLARS)$(OPEN_PAREN)shell ...$(CLOSE_PAREN):$\
			$(NEWLINE)$\
			$(NEWLINE)$\
			$(1)$\
		),$\
		$\
	)$(shell $(1))

# FN__SH__ESCAPE_FOR_SQUOTES -- for single quotes
# FN__SH__ESCAPE_FOR_DQUOTES -- for double quotes
#     Expand the input string to be properly escaped to be used inside single or
#     double quotes within a shell expression. (Neither the leading nor trailing
#     quotes are generated.)
#   PARAMETERS:
#     1: The string to escape

FN__SH__ESCAPE_FOR_SQUOTES = $(subst ','\'',$(1))
FN__SH__ESCAPE_FOR_DQUOTES = $(subst ",\",$(subst $(DOLLARS),\$(DOLLARS),$(1)))

# FN__EVAL__ESCAPE_FOR_MAKE_EVAL -- Similar to $(value ...) but can be applied
#     to non-variables and multiple times:
#   PARAMETERS:
#     1: The string to escape

FN__EVAL__ESCAPE_FOR_MAKE_EVAL = $\
	$(subst \
		$(SPACE),$\
		$(DOLLARS)$(OPEN_PAREN)SPACE$(CLOSE_PAREN),$\
		$(subst \
			$(CLOSE_CURLEY_BRACES),$\
			$(DOLLARS)$(OPEN_PAREN)CLOSE_CURLEY_BRACES$(CLOSE_PAREN),$\
			$(subst \
				$(OPEN_CURLEY_BRACES),$\
				$(DOLLARS)$(OPEN_PAREN)OPEN_CURLEY_BRACES$(CLOSE_PAREN),$\
				$(subst \
					$(COMMA),$\
					$(DOLLARS)$(OPEN_PAREN)COMMA$(CLOSE_PAREN),$\
					$(subst \
						_PAREN@@@,$\
						_PAREN$(CLOSE_PAREN),$\
						$(subst \
							$(CLOSE_PAREN),$\
							$(DOLLARS)$(OPEN_PAREN)CLOSE_PAREN@@@,$\
							$(subst \
								$(OPEN_PAREN),$\
								$(DOLLARS)$(OPEN_PAREN)OPEN_PAREN@@@,$\
								$(subst \
									$(DOLLARS),$\
									$(DOLLARS)$(DOLLARS),$\
									$(subst \
										$(HASH),$\
										$(BACKSLASH)$(HASH),$\
										$(subst \
											$(BACKSLASH),$\
											$(BACKSLASH)$(BACKSLASH),$\
											$(subst \
												$(UNEXPANDED_NO_WHITESPACE_LINEBREAK),$\
												,$\
												$(1)$\
											)$\
										)$\
									)$\
								)$\
							)$\
						)$\
					)$\
				)$\
			)$\
		)$\
	)

#   Note:
#     These two funcitons are taken (almost directly) from the GNU Make manual
#     "8.7 The call function"

# FN__PATHSEARCH
#     Find binary for command in the current environment PATH
#   PARAMETERS:
#     1: The command to search for
FN__PATHSEARCH = $(firstword $(wildcard $(addsuffix /$(1),$(subst :,$(SPACE),$(PATH)))))

# FN__MAP
#     All the results of passing each word in list to the specified function
#   PARAMETERS:
#     1: The function to call
#     2: The list of words to pass (one at a time) to the function
FN__MAP = $(foreach a,$(2),$(call $(1),$(a)))

# FN__IS_ABSOLUTE_PATH
# FN__IS_RELATIVE_PATH
#     Does the argument start with a `/`? Result is non-empty when true
#   PARAMETERS:
#     1: The path

FN__IS_ABSOLUTE_PATH = $(if $(patsubst /%,,$(1)),,ABSOLUTE)
FN__IS_RELATIVE_PATH = $(if $(patsubst /%,,$(1)),RELATIVE,)

# FN__SIMPLIFY_PATHS
# FN__SIMPLIFY_EXECUTABLE_PATHS
#     Make the paths relative to the PWD when applicable. FN__SIMPLIFY_EXECUTABLE_PATHS
#     prefaces these with `./` where FN__SIMPLIFY_PATHS does not.
#   PARAMETERS:
#     1: The list of paths

# Add these two 2: PWD of $(1)
#               3: PWD of result
FN__SIMPLIFY_PATHS = \
	$(foreach \
		each_path,$\
		$(patsubst \
			./%,$\
			$(patsubst \
				%//,$\
				%/,$\
				$(PWD)/$\
			)%,$\
			$(1)$\
		),$\
		$(if \
			$(filter \
				$(patsubst \
					%//,$\
					%/,$\
					$(PWD)/$\
				)%,$\
				$(each_path)$\
			),$\
			$(patsubst \
				$(patsubst \
					%//,$\
					%/,$\
					$(PWD)/$\
				)%,$\
				%,$\
				$(each_path)$\
			),$\
			$(each_path)$\
		)$\
	)
# Change this to reuse code from FN__SIMPLIFY_PATHS:
FN__SIMPLIFY_EXECUTABLE_PATHS = \
	$(foreach \
		each_path,$\
		$(patsubst \
			./%,$\
			$(patsubst \
				%//,$\
				%/,$\
				$(PWD)/$\
			)%,$\
			$(1)$\
		),$\
		$(if \
			$(filter \
				$(patsubst \
					%//,$\
					%/,$\
					$(PWD)/$\
				)%,$\
				$(each_path)$\
			),$\
			$(patsubst \
				$(patsubst \
					%//,$\
					%/,$\
					$(PWD)/$\
				)%,$\
				./%,$\
				$(each_path)$\
			),$\
			$(if \
				$(filter \
					/% ./% ../%,$\
					$(each_path)$\
				),$\
				$(each_path),$\
				./$(each_path)$\
			)$\
		)$\
	)

## Function:
# FN__LIST_PATH_ANCESTORS
#     For any pathname, if it does not contain a `/`, return an empty list,
#     paths that contain it.
#
#     ie. for `foo/bar/baz/bat/bop` return the list: `foo` `foo/bar` `foo/bar/baz` `foo/bar/baz/bat`
#   PARAMETERS:
#     1: The pathname to deconstruct

FN__LIST_PATH_ANCESTORS = $(call FN__DEBUGABLE_SUBSHELL,\
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

DIGITS              :=  $(strip  0  1  2  3  4  5  6  7  8  9)
ALPHABET_UPPER_CASE :=  $(strip  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z)
ALPHABET_LOWER_CASE :=  $(strip  a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z)
ZERO_TO_NINETYNINE  :=  $(patsubst 0%,%,$(foreach tens,$(DIGITS),$(foreach ones,$(DIGITS),$(tens)$(ones))))
NUMBERS              =  $(ZERO_TO_NINETYNINE)
ALPHABET_INDECIES   :=  $(wordlist 2,$(words zero $(ALPHABET_UPPER_CASE)),$(ZERO_TO_NINETYNINE))
ASCII_CHARS_FROM_32 :=  $(SPACE) " $(HASH) $(DOLLARS) % & ' $(OPEN_PAREN) $(CLOSE_PAREN) * + $(COMMA) - . / $\
							$(DIGITS) : ; < = > ? $\
						@ $(ALPHABET_UPPER_CASE) [ $(BACKSLASH) ] ^ _ $\
						` $(ALPHABET_LOWER_CASE) $(OPEN_CURLEY_BRACES) | $(CLOSE_CURLEY_BRACES) ~


## Functions:
# FN__REVERSE_WORDS
#     Reverse the order of the list of words
#   PARAMETERS:
#      1: The list of words to be reversed
FN__REVERSE_WORDS = \
	$(if \
		$(filter \
			0 1,$\
			$(words \
				$(1)$\
			)$\
		),$\
		$(1),$\
		$(call \
			FN__REVERSE_WORDS,$\
			$(wordlist \
				2,$\
				$(words \
					$(1)$\
				),$\
				$(1)$\
			)$\
		) $(firstword \
			$(1)$\
		)$\
	)


# FN__INCREMENT
#     Increment argument.
#   PARAMETERS:
#      1: Number to increment
FN__INCREMENT = \
	$(if \
		$(filter \
			-1 0,$\
			$(1)$\
		),$\
		$(if $(filter 0,$(1)),1,0),$\
		$(if \
			$(filter-out \
				$(wordlist \
					2,$\
					$(lastword $(NUMBERS)),$\
					$(NUMBERS)$\
				),$\
				$(1)$\
			),$\
			$(if \
				$(filter \
					$(wordlist \
						3,$\
						$(words $(NUMBERS)),$\
						$(NUMBERS)$\
					),$\
					$(patsubst -%,%,$(1))$\
				),$\
				-$(call \
					FN__DECREMENT,$\
					$(patsubst \
						-%,$\
						%,$\
						$(1)$\
					)$\
				),$\
				$(error \
					Input "$(1)" not supported by FN__INCREMENT$\
				)$\
			),$\
			$(word \
				$(1),$\
				$(wordlist \
					3,$\
					$(words $(NUMBERS)),$\
					$(NUMBERS)$\
				)$\
			)$\
		)$\
	)

# FN__DECREMENT
#     Decrement argument.
#   PARAMETERS:
#      1: Number to decrement
FN__DECREMENT = \
	$(if \
		$(filter \
			1 0,$\
			$(1)$\
		),$\
		$(if $(filter 0,$(1)),-1,0),$\
		$(if \
			$(filter-out \
				$(wordlist \
					2,$\
					$(words \
						$(NUMBERS)$\
					),$\
					$(NUMBERS)$\
				),$\
				$(1)$\
			),$\
			$(if \
				$(filter \
					$(wordlist \
						1,$\
						$(word $(words $(NUMBERS)),$(NUMBERS)),$\
						$(NUMBERS)$\
					),$\
					$(patsubst -%,%,$(1))$\
				),$\
				-$(call \
					FN__INCREMENT,$\
					$(patsubst \
						-%,$\
						%,$\
						$(1)$\
					)$\
				),$\
				$(error \
					Input "$(1)" not supported by FN__DECREMENT$\
				)$\
			),$\
			$(word \
				$(1),$\
				$(NUMBERS)$\
			)$\
		)$\
	)

# FN__ADD__INTERNAL (internal)
# FN__SUBTRACT__INTERNAL (internal)
#     Do the actual addition / subtraction on positive numbers.
#   PARAMETERS:
#      1: Number to add
#      2: Number to add
#      3: function name default FN__ADD)
FN__ADD__INTERNAL = \
	$(if \
		$(filter 0,$(1) $(2)),$\
		$(firstword $(filter-out 0,$(1) $(2)) 0),$\
		$(if \
			$(word \
				$(2),$\
				$(wordlist \
					$(1),$\
					$(words \
						$(NUMBERS)$\
					),$\
					$(wordlist \
						3,$\
						$(words \
							$(NUMBERS)$\
						),$\
						$(NUMBERS)$\
					)$\
				)$\
			),$\
			$(word \
				$(2),$\
				$(wordlist \
					$(1),$\
					$(words \
						$(NUMBERS)$\
					),$\
					$(wordlist \
						3,$\
						$(words \
							$(NUMBERS)$\
						),$\
						$(NUMBERS)$\
					)$\
				)$\
			),$\
			$(error \
				Sum of "$(1)" + "$(2)" out of range for $(3)$\
			)$\
		)$\
	)

FN__SUBTRACT__INTERNAL = \
	$(if \
		$(filter 1 0,$(2)),$\
		$(if \
			$(filter 1,$(2)),$\
			$(call \
				FN__DECREMENT,$\
				$(1)$\
			),$\
			$(1)$\
		),$\
		$(if \
			$(filter 1 0,$(1)),$\
			$(if \
				$(filter 1,$(1)),$\
				$(call \
					FN__INCREMENT,$\
					$(2)$\
				),$\
				-$(2)$\
			),$\
			$(word \
				$(1),$\
				$(call \
					FN__REVERSE_WORDS,$\
					$(foreach \
						neg,$\
						$(wordlist \
							2,$\
							$(2),$\
							$(NUMBERS)$\
						),$\
						-$(neg)$\
					)$\
				) $(NUMBERS)$\
			)$\
		)$\
	)

# FN__ADD
#     Add two numbers.
#   PARAMETERS:
#      1: Number to add
#      2: Number to add
#      3: (internal) function name default FN__ADD)
FN__ADD = \
	$(if \
		$(filter -%,$(1)),$\
		$(if \
			$(filter -%,$(2)),$\
			-$(call \
				FN__ADD__INTERNAL,$\
				$(patsubst \
					-%,$\
					%,$\
					$(1)$\
				),$\
				$(patsubst \
					-%,$\
					%,$\
					$(2)$\
				),$\
				$(if \
					$(3),$\
					$(3),$\
					FN__ADD$\
				)$\
			),$\
			$(call \
				FN__SUBTRACT__INTERNAL,$\
				$(2),$\
				$(patsubst \
					-%,$\
					%,$\
					$(1)$\
				),$\
				$(if \
					$(3),$\
					$(3),$\
					FN__ADD$\
				)$\
			)$\
		),$\
		$(if \
			$(filter -%,$(2)),$\
			$(call \
				FN__SUBTRACT__INTERNAL,$\
				$(1),$\
				$(patsubst \
					-%,$\
					%,$\
					$(2)$\
				),$\
				$(if \
					$(3),$\
					$(3),$\
					FN__ADD$\
				)$\
			),$\
			$(call \
				FN__ADD__INTERNAL,$\
				$(1),$\
				$(2),$\
				$(if \
					$(3),$\
					$(3),$\
					FN__ADD$\
				)$\
			)$\
		)$\
	)

# FN__SUBTRACT
#     Subtract two numbers.
#   PARAMETERS:
#      1: Number to subtract
#      2: Number to subtract
FN__SUBTRACT = \
	$(call \
		FN__ADD,$\
		$(1),$\
		$(if \
			$(filter \
				-%,$\
				$(2)$\
			),$\
			$(patsubst \
				-%,$\
				%,$\
				$(2)$\
			),$\
			-$(2)$\
		),$\
		FN__SUBTRACT$\
	)

# FN__INT_LESS_THAN
# FN__INT_GREATER_THAN_OR_EQUAL
# FN__INT_GREATER_THAN
# FN__INT_LESS_THAN_OR_EQUAL
# FN__INT_EQUAL_TO
# FN__INT_NOT_EQUAL_TO
#     Compare number on the left to number on the right.
#   Note:
#      While these all work, $(filter ...) and $(filter-out ...) are more practical than
#      $(call,FN__INT_EQUAL_TO,...) and $(call,FN__INT_NOT_EQUAL_TO,...) respectively.
#   PARAMETERS:
#      1: Number to compare
#      2: Number to compare
FN__INT_LESS_THAN             = $(if $(filter -%,$(call FN__SUBTRACT,$(1),$(2))),LESS_THAN,)
FN__INT_GREATER_THAN_OR_EQUAL = $(if $(filter -%,$(call FN__SUBTRACT,$(1),$(2))),,GREATER_THAN_OR_EQUAL)
FN__INT_GREATER_THAN          = $(if $(filter -%,$(call FN__SUBTRACT,$(2),$(1))),GREATER_THAN,)
FN__INT_LESS_THAN_OR_EQUAL    = $(if $(filter -%,$(call FN__SUBTRACT,$(2),$(1))),,LESS_THAN_OR_EQUAL)
FN__INT_EQUAL_TO              = $(if $(filter $(1),$(2)),EQUAL_TO,)
FN__INT_NOT_EQUAL_TO          = $(if $(filter $(1),$(2)),,NOT_EQUAL_TO)


# FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL
#     Generate FN__ definition for function definition that performs some operation for every letter
#     of the alphabet
#   PARAMETERS:
#      1: The name of the new function (without the FN__ prefix)
#      2: The builtin function name to perform on the input
#      3: The (all-caps) case of the letter in the left (from) argument
#      4: The (all-caps) case of the letter in the right  (to) argument
#      5: The left (from) argument letter prefix
#      6: The right  (to) argument letter prefix
#      7: The left (from) argument letter suffix
#      8: The right  (to) argument letter suffix
#      9: Any arguments to insert before left argument [empty string -> no additional arguments]
#     10: Any arguments to insert between right argument and input argument [empty string -> no additional arguments]
#     11: Any arguments to insert after input argument [empty string -> no additional arguments]
FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL = \
	$(call \
		FN__EVAL__DEFINE_MACRO,$\
		FN__$(1),$\
		$(foreach \
			letter_idx,\
			$(ALPHABET_INDECIES),$\
			$(DOLLARS)$(OPEN_PAREN)$(2)$(SPACE)$\
				$(9)$(if $(strip $(9)),$(COMMA),)$\
				$(5)$(word $(letter_idx),$(ALPHABET_$(3)_CASE))$(7)$(COMMA)$\
				$(6)$(word $(letter_idx),$(ALPHABET_$(4)_CASE))$(8)$(COMMA)$\
			$(10)$(if $(strip $(10)),$(COMMA),)$\
			$(DOLLARS)$\
		)$(SPACE)$\
		$(DOLLARS)$(OPEN_PAREN)1$(CLOSE_PAREN)$\
		$(subst $\
			$(SPACE),$\
			,$\
			$(foreach $\
				letter_idx,$\
				$(ALPHABET_INDECIES),$\
				$(if $(strip $(11)),$(COMMA),)$(11)$(CLOSE_PAREN)$\
			)$\
		),$\
		=$\
	)


## Functions:
# FN__TO_UPPER
# FN__TO_LOWER
# FN__UC_FIRST
# FN__LC_FIRST
# FN__SYMBOLS_INSERT_UNDERSCORES
# FN__TO_SNAKE_CASE
# FN__TO_UPPER_SNAKE_CASE
# FN__TO_TITLE_CASE
# FN__TO_CAMEL_CASE
#     Transform the case of the text provided:
#         * FN__TO_UPPER - Convert to upper case
#         * FN__TO_LOWER - Convert to lower case
#         * FN__UC_FIRST - Convert first character of each word to upper case
#         * FN__LC_FIRST - Convert first character of each word to lower case
#         * FN__SYMBOLS_INSERT_UNDERSCORES - Within camel case symbol names, insert underscore between
#               "words" (denoted by a capital letters preceeded by lower case letters)
#         * FN__TO_SNAKE_CASE - Convert symbol names to lowercase with "words" delimited by
#               underscores
#         * FN__TO_UPPER_SNAKE_CASE - Convert symbol names to uppercase with "words" delimited by
#               underscores
#         * FN__TO_TITLE_CASE - Convert symbol names to leading uppercase with "words" starting
#               with uppercase first letter
#         * FN__TO_CAMEL_CASE - Convert symbol names to leading lowercase with "words" starting
#               with uppercase first letter
#   PARAMETERS:
#      1: The text to modify
$(call FN__DEBUGABLE_EVAL,$\
	$(subst $(UNEXPANDED_NO_WHITESPACE_LINEBREAK),,$\
		$(call \
			FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL,$\
			TO_UPPER,$\
			subst,$\
			LOWER,$\
			UPPER,$\
			,$\
			,$\
			,$\
			,$\
			,$\
			,$\
			$\
		)$\
		$(call \
			FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL,$\
			TO_LOWER,$\
			subst,$\
			UPPER,$\
			LOWER,$\
			,$\
			,$\
			,$\
			,$\
			,$\
			,$\
			$\
		)$\
		$(call \
			FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL,$\
			UC_FIRST,$\
			patsubst,$\
			LOWER,$\
			UPPER,$\
			,$\
			,$\
			%,$\
			%,$\
			,$\
			,$\
			$\
		)$\
		$(call \
			FN__EVAL__DEFINE_ALPHABET_FUNCTION__INTERNAL,$\
			LC_FIRST,$\
			patsubst,$\
			UPPER,$\
			LOWER,$\
			,$\
			,$\
			%,$\
			%,$\
			,$\
			,$\
			$\
		)$\
		$(call \
			FN__EVAL__DEFINE_MACRO,$\
			FN__SYMBOLS_INSERT_UNDERSCORES,$\
			$(foreach \
				last_letter_idx,\
				$(ALPHABET_INDECIES),$\
				$(foreach \
					first_letter_idx,\
					$(ALPHABET_INDECIES),$\
					$(DOLLARS)$(OPEN_PAREN)subst$(SPACE)$\
						$(word $(last_letter_idx),$(ALPHABET_LOWER_CASE))$(word $(first_letter_idx),$(ALPHABET_UPPER_CASE))$(COMMA)$\
						$(word $(last_letter_idx),$(ALPHABET_LOWER_CASE))_$(word $(first_letter_idx),$(ALPHABET_UPPER_CASE))$(COMMA)$\
					$(DOLLARS)$\
				)$\
			)$(SPACE)$\
			$(DOLLARS)$(OPEN_PAREN)subst $\
				-$(COMMA)$\
				_$(COMMA)$\
				$(DOLLARS)$(OPEN_PAREN)1$(CLOSE_PAREN)$\
			$(CLOSE_PAREN)$\
			$(foreach \
				last_letter_idx,\
				$(ALPHABET_INDECIES),$\
				$(foreach \
					first_letter_idx,\
					$(ALPHABET_INDECIES),$\
					$(CLOSE_PAREN)$(DOLLARS)$\
				)$\
			)$(SPACE),$\
			=$\
		)$\
	)$\
)


FN__TO_SNAKE_CASE = \
	$(call \
		FN__TO_LOWER,$\
		$(call \
			FN__SYMBOLS_INSERT_UNDERSCORES,$\
			$(1)$\
		)$\
	)

FN__TO_UPPER_SNAKE_CASE = \
	$(call \
		FN__TO_UPPER,$\
		$(call \
			FN__SYMBOLS_INSERT_UNDERSCORES,$\
			$(1)$\
		)$\
	)

FN__TO_TITLE_CASE = \
	$(foreach \
		each_symbol,$\
		$(1),$\
		$(subst \
			$(SPACE),$\
			,$\
			$(call \
				FN__UC_FIRST,$\
				$(subst \
					_,$\
					$(SPACE),$\
					$(call \
						FN__TO_SNAKE_CASE,$\
						$(each_symbol)$\
					)$\
				)$\
			)$\
		)$\
	)

FN__TO_CAMEL_CASE = \
	$(call \
		FN__LC_FIRST,$\
		$(call \
			FN__TO_TITLE_CASE,$\
			$(1)$\
		)$\
	)


# FN__EVAL__EXPAND_FUNCTION_WITH_ARGS
#     Inject arguments into unexpanded function definition.
#   PARAMETERS:
#      1: Name of function defintition to expand
#      2-27: The argument values to be injected (corresponding to $(1)-$(26) respectively)
$(call FN__DEBUGABLE_EVAL,$\
	$(subst $(UNEXPANDED_NO_WHITESPACE_LINEBREAK),,$\
		$(call \
			FN__EVAL__DEFINE_MACRO,$\
			FN__EVAL__EXPAND_FUNCTION_WITH_ARGS,$\
			$(DOLLARS)$(OPEN_PAREN)subst \
				$(DOLLARS)$(OPEN_PAREN)UNEXPANDED_NO_WHITESPACE_LINEBREAK$(CLOSE_PAREN)$(COMMA)$\
				$(COMMA)$\
				$(foreach \
					arg_idx,\
					$(ALPHABET_INDECIES),$\
					$(DOLLARS)$(OPEN_PAREN)subst$(SPACE)$\
						$(call \
							FN__EVAL__ESCAPE_FOR_MAKE_EVAL,$\
							$(DOLLARS)$(OPEN_PAREN)$(arg_idx)$(CLOSE_PAREN)$\
						)$(COMMA)$\
						$(DOLLARS)$(OPEN_PAREN)$(call FN__INCREMENT,$(arg_idx))$(CLOSE_PAREN)$(COMMA)$\
					$(DOLLARS)$\
				)$(SPACE)$\
				$(DOLLARS)$(OPEN_PAREN)subst $\
					$(DOLLARS)$(OPEN_PAREN)UNEXPANDED_NO_WHITESPACE_LINEBREAK$(CLOSE_PAREN)$(COMMA)$\
					$(COMMA)$\
					$(DOLLARS)$(OPEN_PAREN)value $(DOLLARS)$(OPEN_PAREN)1$(CLOSE_PAREN)$(CLOSE_PAREN)$\
				$(CLOSE_PAREN)$\
				$(foreach \
					arg_idx,$\
					$(ALPHABET_INDECIES),$\
					$(CLOSE_PAREN)$(DOLLARS)$\
				)$(SPACE)$\
			$(CLOSE_PAREN),$\
			=$\
		)$\
	)$\
)


## Function:
# FN__EVAL__DEFINE_ON_FIRST_USE
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
#     3: (FN__EVAL__DEFINE_ON_FIRST_USE only) internal setter function. Defaults to
#            "FN__INTERNAL_DEFINE_CACHED_MACRO_NOW". Used for debugging.
#
# FN__EVAL__INTERNAL_DEFINE_CACHED_MACRO_NOW
# FN__INTERNAL_DEFINE_CACHED_MACRO_NOW
#     These two variations of this function define the cached macro immediately (along with
#     the flag indicating that it's already been computed.)
#   PARAMETERS:
#     Same as above.

FN__EVAL__INTERNAL_DEFINE_CACHED_MACRO_NOW = $\
	$(call FN__EVAL__DEFINE_MACRO,$(1)___CACHED_DEFINED,1) \
	$(call FN__EVAL__DEFINE_MACRO,$(1)___CACHED_VALUE,$(2))
FN__INTERNAL_DEFINE_CACHED_MACRO_NOW = $\
	$(call \
		FN__EVAL__EXPAND_FUNCTION_WITH_ARGS,$\
		FN__DEBUGABLE_EVAL,$\
		$(call \
			FN__EVAL__EXPAND_FUNCTION_WITH_ARGS,$\
			FN__EVAL__INTERNAL_DEFINE_CACHED_MACRO_NOW,$\
			$(1),$\
			$(2)$\
		)$\
	)

FN__EVAL__DEFINE_ON_FIRST_USE = $\
	$(call \
		FN__EVAL__DEFINE_MACRO,$\
		$(1),$\
		$(DOLLARS)$(OPEN_PAREN)if$(SPACE)$\
			$(DOLLARS)$(OPEN_PAREN)$(1)___CACHED_DEFINED$(CLOSE_PAREN)$(COMMA)$\
			$(COMMA)$\
			$(call \
				$(if $(3),$(3),FN__INTERNAL_DEFINE_CACHED_MACRO_NOW),$\
				$(1),$\
				$(2)$\
			)$\
		$(CLOSE_PAREN)$(DOLLARS)$(OPEN_PAREN)$(1)___CACHED_VALUE$(CLOSE_PAREN),$\
		=$\
	)
FN__DEFINE_ON_FIRST_USE = $\
	$(call FN__DEBUGABLE_EVAL,$\
		$(call \
			FN__EVAL__DEFINE_ON_FIRST_USE,$\
			$(1),$\
			$(2)$\
		)$\
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
FN__BUILTIN_FRIENDLY_WHICH = \
	$(call \
		FN__DEBUGABLE_SUBSHELL,$\
		$(call \
			FN__SH__BUILTIN_FRIENDLY_WHICH,$\
			$(1)$\
		)$\
	)

# FN__PREFER_EXECUTABLE_FILE_WHICH
#     Similar to FN__BUILTIN_FRIENDLY_WHICH, but prefers command executable
#     files over shell built-ins, aliases or functions. Falls back to shell
#     implementations when executable file isn't found. This is intended to
#     be less tightly coupled to the shell.
#   PARAMETERS:
#     1: The command to resolve
FN__PREFER_EXECUTABLE_FILE_WHICH = \
	$(if \
		$(call \
			FN__PATHSEARCH,$\
			$(1)$\
		),$\
		$(call \
			FN__PATHSEARCH,$\
			$(1)$\
		),$\
		$(call \
			FN__BUILTIN_FRIENDLY_WHICH,$\
			$(1)$\
		)$\
	)


# FN__PROJECT_WHICH
#     Resolve the command in according with the project preference set in
#     $(PROJECT_PREFERED_COMMAND_RESOLUTION)
#   PARAMETERS:
#     1: The command to resolve
FN__PROJECT_WHICH = \
	$(call $(PROJECT_PREFERED_COMMAND_RESOLUTION),$(1))


## Functions:
# FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE
#     Resolves a command with FN__PROJECT_WHICH and stores the result in
#     $(2)_PATH. When macro with dereferenced without the "_PATH" suffix, make generates
#     an error that the required binary isn't installed. The macro name and error message
#     can be customized.
#   PARAMETERS:
#     1: The command to resolve
#     2: The macro name to use for the command [defaults to $(call FN__TO_UPPER_SNAKE_CASE,$(1))]
#     3: The human readable command name [Defaults to $(call FN__TO_TITLE_CASE,$(1))]
#     4: The error message to use when not found [Defaults to
#         "$(3) must be installed. $(3) binary not found in current PATH."]
#   NOTE: Supplying argument 4 makes arguemnt 3 irrelevant
FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE = \
	$(call \
		FN__DEFINE_ON_FIRST_USE,$\
		$(if \
			$(2),$\
			$(2),$\
			$(call \
				FN__TO_UPPER_SNAKE_CASE,$\
				$(1)$\
			)$\
		)_PATH,$\
		$(DOLLARS)$(OPEN_PAREN)call \
			FN__PROJECT_WHICH$(COMMA)$\
			$(1)$\
		$(CLOSE_PAREN)$\
	) \
	$(call \
		FN__DEFINE_ON_FIRST_USE,$\
		$(if \
			$(2),$\
			$(2),$\
			$(call \
				FN__TO_UPPER_SNAKE_CASE,$\
				$(1)$\
			)$\
		),$\
		$(DOLLARS)$(OPEN_PAREN)if \
			$(DOLLARS)$(OPEN_PAREN)$\
				$(if \
					$(2),$\
					$(2),$\
					$(call \
						FN__TO_UPPER_SNAKE_CASE,$\
						$(1)$\
					)$\
				)_PATH$(CLOSE_PAREN)$(COMMA)$\
			$(DOLLARS)$(OPEN_PAREN)call$(SPACE)$\
				FN__SIMPLIFY_EXECUTABLE_PATHS$(COMMA)$\
				$(DOLLARS)$(OPEN_PAREN)$\
					$(if \
						$(2),$\
						$(2),$\
						$(call \
							FN__TO_UPPER_SNAKE_CASE,$\
							$(1)$\
						)$\
					)_PATH$(CLOSE_PAREN)$\
			$(CLOSE_PAREN)$(COMMA)$\
			$(DOLLARS)$(OPEN_PAREN)call \
				FN__DEBUGABLE_EVAL$(COMMA)$\
				$(DOLLARS)$(OPEN_PAREN)error $\
					$(if \
						$(4),$\
						$(4),$\
						$(if \
							$(3),$\
							$(3),$\
							$(call \
								FN__TO_TITLE_CASE,$\
								$(1)$\
							)$\
						) must be installed. $\
						$(if \
							$(3),$\
							$(3),$\
							$(call \
								FN__TO_TITLE_CASE,$\
								$(1)$\
							)$\
						) binary not found in current PATH.$\
					)$\
				$(CLOSE_PAREN)$\
			$(CLOSE_PAREN)$\
		$(CLOSE_PAREN)$\
	)


## Functions:
# FN__VERIFY_COMMAND_PRESENT_WITH_CUSTOM_ERROR_MESSAGE
#     Specifies a custom error message to use in a particular context.
#   PARAMETERS:
#     1: The command's macro name
#     2: The error message to use when not found
FN__VERIFY_COMMAND_PRESENT_WITH_CUSTOM_ERROR_MESSAGE = \
	$(if \
		$($(1)_PATH$),$\
		,$\
		$(error $(2))$\
	)


### Common binaries:

# $(SHELL) will usually be either of these two
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,sh,POSIX_SHELL)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,bash,BASH_SHELL)


$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,echo)
$(call FN__DEFINE_COMMAND_DISAMBIGUATOR_ON_FIRST_USE,mkdir)

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

FN__SH__ECHO_THEN_EXECUTE = \
	$(if \
		$(filter-out \
			ALWAYS_ECHO,\
			$(firstword $(2) $(SILENT_MODE))\
		),$\
		,$\
		>&2 $(ECHO) '$(call FN__SH__ESCAPE_FOR_SQUOTES,$(1))' ; $\
	)$(1)
FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE = if $(1) ; then $(call FN__SH__ECHO_THEN_EXECUTE,$(2),$(3)) ; fi


## Function:
# FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE
#     Generate the Makefile rule to create an empty directory so these can
#     all be generated in a loop.
#   PARAMETERS:
#     1: The the name of the directory

define FN__EVAL__GENERATE_AUTOCREATED_DIRECTORY_RULE


$(call FN__SIMPLIFY_PATHS,$(1)):
	$(SILENCE_WHEN_NOT_VERBOSE)$(call FN__SH__IF_CONDITION_ECHO_THEN_EXECUTE,! [ -d "$(call FN__SIMPLIFY_PATHS,$(1))" ],$(MKDIR) -p $(call FN__SIMPLIFY_PATHS,$(1)))


endef




# FN__IS_NONEMPTY_DIR
#     True (non-empty string) when the path refers to a non-empty directory
#   PARAMETERS:
#     1: The directory to check
FN__IS_NONEMPTY_DIR = $(if $(wildcard $(1)/*),NON_EMPTY_DIR,)

# FN__IS_DIR
#     True (non-empty string) when the path refers to a directory
#   PARAMETERS:
#     1: The directory to check
FN__IS_DIR = $(if $(wildcard $(1)/.),DIR,)

# directories to exclude from recursive searches:
SPECIAL_DIRS_TO_IGNORE := $(sort . .. $(SPECIAL_DIRS_TO_IGNORE))


# FN__STRIP_TRAILING_SLASH
#     Strip trailing slashes from all directories except `\` or
#     `/.` which are normalized to `/`. Any trailing `/.` is also
#     removed.
#   PARAMETERS:
#     1: List of directories to normalize
FN__STRIP_TRAILING_SLASH = \
	$(sort \
		$(patsubst \
			%,$\
			/,$\
			$(filter / /.,$(1))$\
		) $(patsubst \
			%/.,$\
			%,$\
			$(patsubst \
				%/,$\
				%,$\
				$(filter-out / /.,$(1))$\
			)$\
		)$\
	)


# FN__APPEND_TO_FILEPATH
#     Roughly this is equivilant to $(1)/$(2), but special care
#     is taken to avoid double slash or leading `./`. Every directory
#     in $(1) is combined with every filename/pattern in $(2), so the
#     word count of the result will be the product of the word count of
#     the two arguments.
#   PARAMETERS:
#     1: The directory name to append to
#     2: The filename to be appended
FN__APPEND_TO_FILEPATH = \
	$(foreach \
		each_dir,$\
		$(call FN__STRIP_TRAILING_SLASH,$(1)),$\
		$(foreach \
			each_file,$\
			$(2),$\
			$(patsubst \
				./%,$\
				%,$\
				$(patsubst %/,%,$(each_dir))/$(each_file)$\
			)$\
		)$\
	)


# FN__FIND_SUBDIRS_IN
#     Non-recursively find all subdirectories in given directory.
#     All direcoties in $(SPECIAL_DIRS_TO_IGNORE) are removed from
#     the resulting list.
#   PARAMETERS:
#     1: The directory to search
FN__FIND_SUBDIRS_IN = \
	$(filter-out \
		$(call \
			FN__APPEND_TO_FILEPATH,$\
			%,$\
			$(SPECIAL_DIRS_TO_IGNORE)$\
		) $(SPECIAL_DIRS_TO_IGNORE),$\
		$(patsubst \
			%/.,$\
			%,$\
			$(wildcard $(call FN__APPEND_TO_FILEPATH,$(1),*/. .*/.))$\
		)$\
	)

# FN__SEARCH_DIR_FOR_PATTERN
#     Non-recursively find all subdirectories in given directory.
#     All direcoties in $(SPECIAL_DIRS_TO_IGNORE) are removed from
#     the resulting list.
#   PARAMETERS:
#     1: The directory to search
#     2: The wildcard filename patter to search for
#     3: If non-empty, return list of directories, otherwise
#            return files.
FN__SEARCH_DIR_FOR_PATTERN = \
	$(sort \
		$(foreach \
			each_subdir,$\
			$(call FN__FIND_SUBDIRS_IN,$(1)),$\
			$(call \
				FN__SEARCH_DIR_FOR_PATTERN,$\
				$(each_subdir),$\
				$(if $(2),$(2),*)$\
			)$\
		) $(foreach \
			each_match,$\
			$(wildcard \
				$(call \
					FN__APPEND_TO_FILEPATH,$\
					$(1),$\
					$(if $(2),$(2),*)$\
				)$\
			),$\
			$(if \
				$(call FN__IS_DIR,$(each_match)),$\
				$(if $(3),$(each_match),),$\
				$(if $(3),,$(each_match))$\
			)$\
		)$\
	)


# FN__GET_NEW_UNIQUE_SYMBOL
#     Generate a unique symbol name by appending the next value of a
#     counter to a given prefix string
#   PARAMETERS:
#     1: Symbol prefix (defaults to UNIQUE_NAME)
UNIQUE_SYMBOL_COUNTER__INTERNAL := 1
FN__GET_NEW_UNIQUE_SYMBOL = \
	$(if \
		$(1),$\
		$(1),$\
		UNIQUE_NAME$\
	)_$(lastword $(UNIQUE_SYMBOL_COUNTER__INTERNAL))$\
	$(call \
		FN__DEBUGABLE_EVAL,$\
		$(call \
			FN__EVAL__DEFINE_MACRO,$\
			UNIQUE_SYMBOL_COUNTER__INTERNAL,$\
			$(DOLLARS)$(OPEN_PAREN)words \
				$(DOLLARS)$(OPEN_PAREN)UNIQUE_SYMBOL_COUNTER__INTERNAL$(CLOSE_PAREN) $\
					SOME_WORD$\
			$(CLOSE_PAREN),$\
			+=$\
		)$\
	)


# EVAL__FUNC_LIB_MAKEFILE_FOOTER
#     Generic Makefile targets supporting above functions. (This
#     should be `$(eval ...)` at the end of the Makefile).

define EVAL__FUNC_LIB_MAKEFILE_FOOTER

# Dummy target, to put makefile into verbose and/or verbose_debug mode.
# The dependancy expands to "all" there are no explicit goals besides
# "verbose" and/or "verbose_debug"
# See $(VERBOSE_MODE) above.
verbose: $(if $(filter-out verbose verbose_debug,$(MAKECMDGOALS)),,all)
	$(SILENCE_WHEN_NOT_VERBOSE)# NoOp: Avoid "Nothing to be done for verbose" message

verbose_debug: $(if $(filter-out verbose verbose_debug,$(MAKECMDGOALS)),,all)
	$(SILENCE_WHEN_NOT_VERBOSE)# NoOp: Avoid "Nothing to be done for verbose_debug" message

FORCE:


endef


