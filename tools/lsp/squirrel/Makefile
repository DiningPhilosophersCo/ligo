PACKAGE := squirrel

LIGO_SEVERITY = LIGO_SEVERITY="debug"
LIGO_ENV = LIGO_ENV="development"
BUILD_FLAGS = $(LIGO_SEVERITY) $(LIGO_ENV)

STACK_DEV_OPTIONS = --fast --ghc-options '-Werror -freverse-errors' --test --no-run-tests
STACK_DEV = $(BUILD_FLAGS) stack build $(STACK_DEV_OPTIONS)

.DEFAULT_GOAL := all

all: watch

FORCE:

grammar: ; $(MAKE) -C $@

clean:
	$(RM) -r grammar/*/src
	$(RM) grammar/*/binding.gyp
	stack clean

build: grammar
	$(STACK_DEV)

watch: grammar
	$(STACK_DEV) --file-watch

.PHONY: all clean grammar build watch FORCE
