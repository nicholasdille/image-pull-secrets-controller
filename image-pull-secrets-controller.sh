#!/bin/bash

if ! test -d /run/secrets/kubernetes.io/serviceaccount; then
    echo "ERROR: Missing service account information in /run/secrets/kubernetes.io/serviceaccount."
    exit 1
fi

for tool in kubectl curl jq; do
    if ! type ${tool} >/dev/null 2>&1; then
        echo "ERROR: I need ${tool} to work."
        exit 1
    fi
done

kubectl config set-cluster local --server=https://kubernetes --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl config set-credentials local --token=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
kubectl config set-context local --cluster=local --user=local --namespace=$(cat /run/secrets/kubernetes.io/serviceaccount/namespace)

if ! kubectl get namespaces >/dev/null 2>&1; then
    echo "ERROR: Failed to establish cluster connection."
    exit 1
fi

SECRETS=$(
    kubectl get secrets --output json | \
        jq '.items[] | select(.type == "kubernetes.io/dockerconfigjson") | .metadata.name'
)
if test -z "${SECRETS}"; then
    echo "ERROR: No secrets found."
    exit 1
fi

function cleanup() {
    info "Cleaning up..."
    info "Goodbye!"
}
trap cleanup EXIT

TIMESTAMP=$(date +%s)
kubectl get namespaces --watch --output-watch-events --output json | \
    jq --compact-output --monochrome-output --unbuffered 'del(.object.metadata.managedFields)' | \
    while read EVENT; do
        event_type=$(echo ${EVENT} | jq --raw-output '.type')

        case "${event_type}" in
            ADDED)
                :
                ;;
        esac

    done