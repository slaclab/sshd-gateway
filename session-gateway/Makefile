RUNTIME ?= sudo docker
TAG ?= latest
REPO ?= slaclab
IMAGE ?= session-gateway

.PHONEY:

all: build push

build: .PHONEY
	$(RUNTIME) build . -t $(REPO)/$(IMAGE):$(TAG)

push:
	$(RUNTIME) push $(REPO)/$(IMAGE):$(TAG)
