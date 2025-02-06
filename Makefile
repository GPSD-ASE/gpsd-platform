# Helm Namespace
NAMESPACE=gpsd
HELM_REPO=.
INPUT_MANIFEST=input-manifest.yml

# Read services from YAML using yq
IMAGES=$(shell yq eval '.images | keys | .[]' $(INPUT_MANIFEST))
VERSIONS=$(shell yq eval '.images | to_entries | map("\(.key)=\(.value)") | .[]' $(INPUT_MANIFEST))

# Convert images to a format usable in Make
define package_helm_chart
	@echo "📦 Packaging $(1) with version $(2)"
	helm package $(HELM_REPO)/$(1) --version $(2) -d $(HELM_REPO)/packages/
endef

define install_helm_chart
	@echo "🚀 Installing/upgrading $(1) with version $(2)"
	helm upgrade --install $(1) $(HELM_REPO)/packages/$(1)-$(2).tgz --namespace $(NAMESPACE) --create-namespace
endef

all: package install

package: ## Package Helm charts
	$(foreach svc_ver, $(VERSIONS), $(eval svc=$(shell echo $(svc_ver) | cut -d= -f1)) $(eval ver=$(shell echo $(svc_ver) | cut -d= -f2)) $(call package_helm_chart,$(svc),$(ver)))

install: ## Install/Upgrade Helm charts
	$(foreach svc_ver, $(VERSIONS), $(eval svc=$(shell echo $(svc_ver) | cut -d= -f1)) $(eval ver=$(shell echo $(svc_ver) | cut -d= -f2)) $(call install_helm_chart,$(svc),$(ver)))

clean: ## Cleanup old Helm packages
	@echo "🧹 Cleaning Helm packages..."
	rm -rf $(HELM_REPO)/packages/*.tgz

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'