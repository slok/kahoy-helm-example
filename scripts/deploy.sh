#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufCo pipefail
export SHELLOPTS
IFS=$'\t\n'

# This script needs some dependencies to run correctly, check them before start
command -v kahoy >/dev/null 2>&1 || { echo 'Please install kahoy'; exit 1; }

# Used to load the manifests to be deployed by Kahoy.
[ -z "${MANIFESTS_PATH:-}" ] && echo "MANIFESTS_PATH env var is required" && exit 1;
# Environment is used as part of the identifier on Kahoy kubernetes state store.
# Used in case of different env apps are deployed on the same cluster using multiple
# deployment steps.
[ -z "${ENVIRONMENT:-}" ] && echo "ENVIRONMENT env var is required" && exit 1;

# The path where the report will be stored.
KAHOY_REPORT="${KAHOY_REPORT:-./kahoy-report.json}"

function kahoy_apply() {
    kahoy apply \
        --provider "kubernetes" \
        --kube-provider-id "kahoy-helm-example-${ENVIRONMENT}" \
        --kube-provider-namespace "kahoy-helm-example" \
        --fs-new-manifests-path "${MANIFESTS_PATH}" \
        --report-path "${KAHOY_REPORT}" \
        --auto-approve
}

case "${1:-"dry-run"}" in
# Sync only the changed (includes removed) resources.
"run")
    KAHOY_INCLUDE_CHANGES=true kahoy_apply
    ;;
"diff")
    KAHOY_INCLUDE_CHANGES=true KAHOY_DIFF=true kahoy_apply | colordiff
    ;;
"dry-run")
    KAHOY_INCLUDE_CHANGES=true KAHOY_DRY_RUN=true kahoy_apply
    ;;

# Sync all the resources.
"sync-run")
    kahoy_apply
    ;;
"sync-diff")
    KAHOY_DIFF=true kahoy_apply | colordiff
    ;;
"sync-dry-run")
    KAHOY_DRY_RUN=true kahoy_apply
    ;;
*)
    echo "ERROR: Unknown command"
    exit 1
    ;;
esac
