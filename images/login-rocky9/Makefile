RUNTIME ?= sudo podman
TAG ?= latest
REPO ?= docker://docker.io/slaclab
IMAGE ?= login-rocky9

.PHONEY:

all: build push

build: .PHONEY
	$(RUNTIME) build . -t $(REPO)/$(IMAGE):$(TAG)

push: build
	$(RUNTIME) push $(REPO)/$(IMAGE):$(TAG)
