#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufo pipefail
export SHELLOPTS
IFS=$'\t\n'

# This script needs some dependencies to run correctly, check them before start
command -v kubectl >/dev/null 2>&1 || { echo 'Please install kubectl'; exit 1; }
command -v kubedog >/dev/null 2>&1 || { echo 'Please install kubedog'; exit 1; }
command -v jq >/dev/null 2>&1 || { echo 'Please install jq'; exit 1; }


# Waits to all the workload types to be ready based on what ready means for
# kubedog (deployment pods updated, pods up and running...).
# We convert kahoy output into a kubedog multitrack cli format.
function wait_applied() {
    [[ $# -ne 2 ]] && echo "USAGE: wait_applied KAHOY_REPORT_OUTPUT TIMEOUT_SECONDS" && exit 1

    timeout="${2}"
    echo "[*] Waiting applied resources (timeout after $timeout seconds)..."
    echo "${1}" | jq '
    {
    "Deployments": [
        .applied_resources
        | .[]
        | select(.kind == "Deployment")
        | {ResourceName: .name, Namespace: .namespace}
    ],
    "StatefulSets": [
        .applied_resources
        | .[]
        | select(.value.kind == "StatefulSet")
        | {ResourceName: .name, Namespace: .namespace}
    ],
    "DaemonSets": [
        .applied_resources
        | .[]
        | select(.value.kind == "DaemonSet")
        | {ResourceName: .name, Namespace: .namespace}
    ],
    "Jobs": [
        .applied_resources
        | .[]
        | select(.value.kind == "Job")
        | {ResourceName: .name, Namespace: .namespace}
    ]
    }
    ' | kubedog multitrack --timeout "${timeout}"
}

# Wait all the deleted resources. These are the checks:
# - If is a namespaced resourece check the namespace exists.
# - Check if the resource exists.
# - Wait with Kubectl until the resource has been deleted.
function wait_deleted() {
    [[ $# -ne 1 ]] && echo "USAGE: wait_applied KAHOY_REPORT_OUTPUT" && exit 1

    # Parse kahoy output and get all the name, kind and ns of the deleted resources, 
    # then get this data an wait for each of the resources is deleted from the cluster.
    echo "[*] Waiting deleted resources..."
    echo "${1}" | jq -r '.deleted_resources | .[]| [.name, .kind, .namespace] | @tsv' |
    while IFS=$'\t' read -r name kind namespace; do
        ns_arg="" 
        if [ ! -z "${namespace}" ]; then
            # Check the ns is not missing before checking namespaced resource.
            kubectl get ns "${namespace}" >/dev/null 2>&1 || { echo  "  [-] ${kind}/${namespace}/${name}: namespace missing, already deleted"; continue; }

            # Add namespace argument
            ns_arg="--namespace=${namespace}"
        fi

        # Check resource exists.
        kubectl get ${ns_arg} "${kind}/${name}" >/dev/null 2>&1 || { echo  "  [-] ${kind}/${namespace}/${name}: resource missing, already deleted"; continue; }

        # Wait for resource. 
        echo  "  [-] ${kind}/${namespace}/${name}: Waiting for total deletion..."
        kubectl wait ${ns_arg} "${kind}/${name}" --for=delete
    done
}


in="$(cat ${1:-/dev/stdin})"
[ -z "${in}" ] && echo "Empty report" && exit 0;

wait_applied "${in}" "${APPLIED_TIMEOUT:-600}"
wait_deleted "${in}"