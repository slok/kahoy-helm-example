#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufo pipefail
export SHELLOPTS
IFS=$'\t\n'

# This script needs some dependencies to run correctly, check them before start
command -v helm >/dev/null 2>&1 || { echo 'Please install helm'; exit 1; }

SERVICES_PATH="${SERVICE_PATH:-./services}"
CHART_PATH="${CHART_PATH:-./charts/generic}"
GEN_PATH="${GEN_PATH:-./_gen}"

echo "[*] Cleaning ${GEN_PATH}..."
rm -rf "${GEN_PATH}"
mkdir -p "${GEN_PATH}"

echo "[*] Generating manifests..."
set +f # allow expansion.
for service_path in ${SERVICES_PATH}/* ; do
    service_name=$(basename "${service_path}")
    global_config_path="${service_path}/config.yaml"
    global_version_path="${service_path}/version"
    global_version=""

    # If no file, ignore service.
    [ -f "${global_config_path}" ] || { continue; }

    # If global version, set version.
    [ ! -f "${global_version_path}" ] || { global_version=$(cat ${global_version_path}); }

    echo "  [+] ${service_name}:"
    for env_path in ${service_path}/* ; do
        env_config_path="${env_path}/config.yaml"
        env_name=$(basename "${env_path}")
        env_version_path="${env_path}/version"
        
        # If no file, ignore env.
        [ -f "${env_config_path}" ] || { continue; }
        
        # If env version, set version.
        version=${global_version}
        [ ! -f "${env_version_path}" ] || { version=$(cat ${env_version_path}); }
        
        
        # If missing version exit.
        [ ! -z "${version}" ]  || { echo "${service_name}/${env_name} has no version"; exit 1; }

        out_path="${GEN_PATH}/${env_name}/${service_name}"
        mkdir -p ${out_path}
        helm template ${service_name}-${env_name} ${CHART_PATH} \
            -f ${global_config_path} \
            -f ${env_config_path} \
            --set "tag=${version}" \
            --set "environmentType=${env_name}" \
            > ${out_path}/resources.yaml
        
        echo "    [-] ${env_name}: ${version}"
    done
done
set -f