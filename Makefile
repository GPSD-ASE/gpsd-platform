# Helm Namespace
NAMESPACE=gpsd
CHART_NAME=gpsd-platform
INPUT_MANIFEST=input-manifest.yaml

# Read all service names and versions from input-manifest.yaml
SERVICES=$(shell yq eval '.services | keys | .[]' $(INPUT_MANIFEST))
VERSIONS=$(shell yq eval '.services | to_entries | map("\(.key)=\(.value)") | .[]' $(INPUT_MANIFEST))

# Define per-service installation
define install_helm_chart
	helm upgrade --install $(1) ./charts/$(1) --namespace $(NAMESPACE) --set image.tag=$(2)
endef

# Create a new chart for the parent platform
create:
	helm create $(CHART_NAME)

# Deploy all services dynamically
install:
	$(foreach service, $(SERVICES), \
		$(call install_helm_chart,$(service),$(shell yq eval ".services.$(service)" $(INPUT_MANIFEST))) \
	)

# Rollback a specific service to the previous release
rollback:
	helm rollback $(service)

# Delete a specific service
delete:
	helm delete $(service) --namespace $(NAMESPACE)

# List installed services in the specified namespace
list:
	helm list --namespace $(NAMESPACE)

# Update all the services (e.g., after modifying values.yaml or versions)
update:
	$(foreach service, $(SERVICES), \
		helm upgrade $(service) ./charts/$(service) --namespace $(NAMESPACE) --set image.tag=$(shell yq eval ".services.$(service)" $(INPUT_MANIFEST)) \
	)
