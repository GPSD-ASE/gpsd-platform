# Helm Namespace
NAMESPACE=gpsd
CHART_NAME=gpsd-platform
INPUT_MANIFEST=input-manifest.yaml

# Read all service versions from input-manifest.yaml
VERSIONS=$(shell yq eval '.services | to_entries | map("\(.key)=\(.value)") | .[]' $(INPUT_MANIFEST))

# Define per-service installation
define install_helm_chart
	helm upgrade --install $(1) ./charts/$(1) --namespace $(NAMESPACE) --set image.tag=$(2)
endef

create:
	helm create $(CHART_NAME)

# Deploy all services dynamically
install:
	$(foreach service, $(VERSIONS), $(call install_helm_chart,$(service)))

# Package all charts into .tgz files
package:
	@mkdir -p packages
	$(foreach service, $(VERSIONS), helm package ./charts/$(service) -d packages &&)

# Rollback specific service
rollback:
	helm rollback $(service)

# Delete a service
delete:
	helm delete $(service)

# List installed services
list:
	helm list --namespace gpsd