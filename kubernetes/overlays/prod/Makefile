KUBECTL_DEPLOY_CONTEXT ?= 'sshd-gateway'

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context inccorect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

run-dump:
	kubectl kustomize . | yh

dump: run-dump

run-diff:
	kubectl diff -k .

run-apply:
	kubectl apply -k .

apply: ensure-context run-apply

diff: ensure-context run-diff

login-test:
	image=slaclab/login-rocky9 ssh -o sendEnv=image 172.24.5.219

rockylinux9.5-public-image-test:
	image=rockylinux/rockylinux:9.5 ssh -o sendEnv=image 172.24.5.219

kipac-test:
	template=kipac ssh -o sendEnv=template 172.24.5.219

ldmx-test:
	template=ldmx ssh -o sendEnv=template 172.24.5.219

