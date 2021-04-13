RUNTIME ?= sudo docker
TAG ?= latest
REPO ?= slaclab
IMAGE ?= login-centos7

.PHONEY:

all: build push

build: .PHONEY
	$(RUNTIME) build . -t $(REPO)/$(IMAGE):$(TAG)

push:
	$(RUNTIME) push $(REPO)/$(IMAGE):$(TAG)
