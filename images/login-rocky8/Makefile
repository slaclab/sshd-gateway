RUNTIME ?= sudo docker
TAG ?= latest
REPO ?= slaclab
IMAGE ?= login-rocky8

.PHONEY:

all: build push

build: .PHONEY
	$(RUNTIME) build . -t $(REPO)/$(IMAGE):$(TAG)

push: build
	$(RUNTIME) push $(REPO)/$(IMAGE):$(TAG)
