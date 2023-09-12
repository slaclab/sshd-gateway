#all: session-gateway teardown apply

.PHONEY:

session-gateway: .PHONEY
	cd session-gateway && make

#teardown:
#	kubectl delete  deployment.apps/session-gateway
#
#apply:
#	kubectl apply -k kubernetes/overlays/dev/
#
	
