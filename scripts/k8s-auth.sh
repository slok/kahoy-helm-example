#!/bin/bash
# vim: ai:ts=8:sw=8:noet
# Intended to be run from CI
# The script needs these env vars:
# - K8S_CA_B64: The certs CA (in Base64) of the Kuberentes apiserver URL.
# - K8S_SERVER: The Kubernetes apiserver URL.
# - K8S_SA_TOKEN: The token to authenticate against the apiserver.
#
# A way to getting the token is to create a service account (and role, binding..),
# after this, Kubernetes will create the tokens as a secret, from now on, you can
# use this token to authenticate (using `K8S_SA_TOKEN` env var).
#
set -eufCo pipefail
export SHELLOPTS	# propagate set to children by default
IFS=$'\t\n'

# check required commands are in place
command -v kubectl >/dev/null 2>&1 || { echo 'please install kubectl or use an image that has it'; exit 1; }

# generate a kubectl configuration file
mkdir -p "${HOME}/.kube"
cat >| "${HOME}/.kube/config" <<-EOF
	apiVersion: v1
	kind: Config
	clusters:
	- name: default-cluster
	  cluster:
	    certificate-authority-data: ${K8S_CA_B64}
	    server: ${K8S_SERVER}
	contexts:
	- name: default-context
	  context:
	    cluster: default-cluster
	    namespace: default
	    user: default-user
	current-context: default-context
	users:
	- name: default-user
	  user:
	    token: ${K8S_SA_TOKEN}
EOF
