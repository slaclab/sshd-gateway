KUBECTL_DEPLOY_CONTEXT ?= 'sshd-gateway'

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context inccorect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

run-dump:
	kubectl kustomize . | yh

dump: run-dump

run-apply:
	kubectl apply -k .

apply: ensure-context run-apply
