REGISTRY_LOCAL_NAME := local-registry
REGISTRY_LOCAL_PORT := 5000
REGISTRY_CACHE_NAME := dockerhub-cache
KIND_CLUSTER_NAME   := image-pull-secrets
K3D_CLUSTER_NAME    := image-pull-secrets
IMAGE_NAME          := image-pull-secrets

M = $(shell printf "\033[34;1m▶\033[0m")

.PHONY:
build: ; $(info $(M) Building container image...)
	@\
	docker build \
		--tag localhost:$(REGISTRY_LOCAL_PORT)/$(IMAGE_NAME) \
		.

.PHONY:
push: build ; $(info $(M) Pushing container image...)
	@\
	docker push \
		localhost:$(REGISTRY_LOCAL_PORT)/$(IMAGE_NAME)

.PHONY:
deploy: push ; $(info $(M) Deploying service...)
	@\
	echo $@

.PHONY:
deploy-kind: kind deploy

.PHONY:
clean-deploy-kind: clean-kind kind deploy

.PHONY:
deploy-k3d: k3d deploy

.PHONY:
clean-deploy-k3d: clean-k3d k3d deploy

.PHONY:
dockerhub-cache: ; $(info $(M) Creating cache registry for Docker Hub...)
	@\
	running="$$(docker inspect -f '{{.State.Running}}' $(REGISTRY_LOCAL_NAME) 2>/dev/null || true)"; \
	if test "$${running}" != "true"; then \
		docker run \
			--name $(REGISTRY_LOCAL_NAME) \
			--detach \
			--restart=always \
			--publish "127.0.0.1:$(REGISTRY_LOCAL_PORT):5000" \
			registry:2; \
	fi

.PHONY:
clean-dockerhub-cache: ; $(info $(M) Removing cache registry for Docker Hub...)
	@\
	docker rm -f $(REGISTRY_CACHE_NAME)

.PHONY:
local-registry: ; $(info $(M) Creating local registry...)
	@\
	running="$$(docker inspect -f '{{.State.Running}}' $(REGISTRY_CACHE_NAME) 2>/dev/null || true)"; \
	if test "$${running}" != "true"; then \
		docker run \
			--name $(REGISTRY_CACHE_NAME) \
			--detach \
			--restart=always \
			--net=kind \
			--env REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
			registry:2; \
	fi

.PHONY:
clean-local-registry: ; $(info $(M) Removing local registry...)
	@\
	docker rm -f $(REGISTRY_LOCAL_NAME)

.PHONY:
cluster-config: ; $(info $(M) Creating cluster config for local registry...)
	@\
	cat hack/local-registry.yaml | \
		envsubst '$$REGISTRY_LOCAL_PORT' | \
		kubectl --kubeconfig=./kubeconfig apply -f -

.PHONY:
kind-check-wsl2:
	@\
	if test -n "$${WSL_DISTRO_NAME}"; then \
		echo "ERROR: Do not run kind in WSL2."; \
		exit 1; \
	fi

.PHONY:
cluster-wait: ; $(info $(M) Waiting for cluster to become ready...)
	@\
	while kubectl --kubeconfig=./kubeconfig get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.reason=="KubeletReady")].status}{"\n"}{end}' | grep -qE "\sFalse$$"; do \
		sleep 5; \
	done

# Documentation: https://kind.sigs.k8s.io/docs/user/local-registry/
#                https://maelvls.dev/docker-proxy-registry-kind/
.PHONY:
kind-create: kind-check-wsl2 dockerhub-cache local-registry ; $(info $(M) Creating cluster using KinD...)
	@\
	cat hack/kind.yaml | \
		envsubst '$$REGISTRY_LOCAL_NAME,$$REGISTRY_LOCAL_PORT,$$REGISTRY_CACHE_NAME' | \
		kind create cluster --name $(KIND_CLUSTER_NAME) --config -; \
	docker network connect "kind" "$${REGISTRY_LOCAL_NAME}"

.PHONY:
kind-delete: ; $(info $(M) Removing cluster using KinD...)
	@\
	kind delete cluster --name $(KIND_CLUSTER_NAME)

.PHONY:
kind-kubeconfig: ; $(info $(M) Retrieving cluster config using KinD...)
	@\
	kind get kubeconfig --name $(KIND_CLUSTER_NAME) >kubeconfig

.PHONY:
kind: kind-create kind-kubeconfig cluster-wait cluster-config

.PHONY:
k3s-registries: ; $(info $(M) Creating registry configuration for k3s...)
	@\
	sudo mkdir -p /etc/rancher/k3s; \
	cat hack/k3s-registries.yaml | \
		envsubst '$$REGISTRY_LOCAL_NAME,$$REGISTRY_LOCAL_PORT,$$REGISTRY_CACHE_NAME' | \
		sudo tee /etc/rancher/k3s/registries.yaml >/dev/null

.PHONY:
k3d-create: ; $(info $(M) Creating cluster using k3d...)
	@\
	if ! k3d cluster list $(K3D_CLUSTER_NAME) --no-headers 2>/dev/null | grep --quiet $(K3D_CLUSTER_NAME); then \
		k3d cluster create $(K3D_CLUSTER_NAME) \
			--volume "$${PWD}/hack/k3s-registries.yaml:/etc/rancher/k3s/registries.yaml"; \
	fi

.PHONY:
k3d-delete: ; $(info $(M) Removing cluster using k3d...)
	@\
	k3d cluster delete $(K3D_CLUSTER_NAME)

.PHONY:
k3d-kubeconfig: ; $(info $(M) Retrieving cluster config using k3d...)
	@\
	k3d kubeconfig get $(K3D_CLUSTER_NAME) >kubeconfig

# Documentation: https://k3d.io/usage/guides/registries/
.PHONY:
k3d: dockerhub-cache local-registry k3s-registries k3d-create k3d-kubeconfig cluster-wait cluster-config

.PHONY:
clean-kind: kind-delete clean-dockerhub-cache clean-local-registry

.PHONY:
clean-k3d: k3d-delete clean-dockerhub-cache clean-local-registry
