SYSTEM := $(shell uname -s | tr '[:upper:]' '[:lower:]')

KSONNET_VERSION   ?= 0.8.0
JSONNET_FMT       := jsonnet fmt -n 2 --comment-style s --string-style d --max-blank-lines 2

.PHONY: install-tools
install-tools: install-jb install-ksonnet

.PHONY: install-jb
install-jb:
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

.PHONY: install-ksonnet
install-ksonnet:
	wget -nv -P /tmp https://github.com/ksonnet/ksonnet/releases/download/v$(KSONNET_VERSION)/ks_$(KSONNET_VERSION)_$(SYSTEM)_amd64.tar.gz
	tar xvf /tmp/ks_$(KSONNET_VERSION)_$(SYSTEM)_amd64.tar.gz -C ~/bin --strip-components=1 ks_0.8.0_$(SYSTEM)_amd64/ks

.PHONY: lint
lint: lint-jsonnet

.PHONY: lint-jsonnet
lint-jsonnet:
	find . -name '*.jsonnet' -o -name '*.libsonnet' | \
		xargs -n 1 -- $(JSONNET_FMT) --test

.PHONY: fmt
fmt: fmt-jsonnet

.PHONY: fmt-jsonnet
fmt-jsonnet:
	find . -name '*.jsonnet' -o -name '*.libsonnet' | \
		xargs -n 1 -- $(JSONNET_FMT) -i
