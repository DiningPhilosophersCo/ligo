BLST_FILES = $(shell esy echo '\#{@opam/bls12-381-unix.lib}/bls12-381-unix')
PROFILE ?= dev
JS_FILES = threads.js bls12-runtime.js random.js runtime-generated.js evercrypt.js

space := $(null) #
comma := ,


# last refactor: 2021-05-05
.ONESHELL:

all: test

.PHONY: esy
esy: esy.json
	esy
.PHONY: sudo-prompt
sudo-prompt:
	echo "SUDO password for copying files" && sudo true

_http:
	mkdir -p _http

_http/blst.js: esy sudo-prompt _http
	sudo cp $(BLST_FILES)/blst.js _http

_http/blst.wasm: esy sudo-prompt _http
	sudo cp $(BLST_FILES)/blst.wasm _http

_http/index.html: _http
	cp src/bin/index.html _http

_build/default/src/bin/main.bc.js: esy
	esy dune build ./src/bin/main.bc.js --profile $(PROFILE) -j 8

# <<<<<<< HEAD
# _http/%.js: _build/default/src/bin/%.js _build/default/src/bin/main.bc.js _http sudo-prompt
# 	sudo cp $< _http
# =======
$(foreach F, $(JS_FILES), _http/$(F)) _http/main.bc.js: _build/default/src/bin/main.bc.js _http sudo-prompt
	sudo cp $(subst _http,_build/default/src/bin,$@) $@ 
# >>>>>>> a6ca19a17 (Adds makefile)

jsoo: _http/main.bc.runtime.js _http/main.bc.js $(foreach F, $(JS_FILES), _http/$(F)) _http/index.html _http/blst.js _http/blst.wasm
	python3 -m http.server -d _http

# Use install-deps instead of 'install' because usually 'make install' adds a
# binary to the system path and we don't want to confuse users
install-deps:
#	Install ligo/tezos specific system-level dependencies
	sudo scripts/install_native_dependencies.sh
	scripts/install_build_environment.sh # TODO: or scripts/install_opam.sh ?

build-deps:
	export PATH="/usr/local/bin$${PATH:+:}$${PATH:-}"
#	Create opam dev switch locally for use with Ligo, add merlin/etc
	if [ ! -d "./_opam" ];
	then scripts/setup_switch.sh;
	fi
	eval $$(opam config env)
# NEW-PROTOCOL-TEMPORARY
	git submodule sync --recursive
	git submodule update --init --recursive
# NEW-PROTOCOL-TEMPORARY
#	Install OCaml build dependencies for Ligo
	scripts/install_vendors_deps.sh

build: build-deps
	export PATH="/usr/local/bin$${PATH:+:}$${PATH:-}"
	eval $$(opam config env)
#	Build Ligo for local dev use
	scripts/build_ligo_local.sh

test: build
	scripts/check_duplicate_filenames.sh || exit
	export PATH="/usr/local/bin$${PATH:+:}$${PATH:-}"
	eval $$(opam config env)
	scripts/test_ligo.sh

clean:
	dune clean
	rm -fr _coverage_all _coverage_cli _coverage_ligo _http

coverage:
	eval $$(opam config env)
	find . -name '*.coverage' | xargs rm -f
	dune runtest --instrument-with bisect_ppx --force
	bisect-ppx-report html -o ./_coverage_all --title="LIGO overall test coverage"
	bisect-ppx-report summary --per-file
