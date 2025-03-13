# Helm Namespace
NAMESPACE=gpsd
FOLDER_NAME=gpsd-platform
CHART_NAME=gpsd-platform
INPUT_MANIFEST=input-manifest.yaml
REMOTE_CHART_REPOSITORY = gpsd-ase.github.io

# Read all service names and versions from input-manifest.yaml
SERVICES=$(shell yq eval '.services | keys | .[]' $(INPUT_MANIFEST))
VERSIONS=$(shell yq eval '.services | to_entries | map("\(.key)=\(.value)") | .[]' $(INPUT_MANIFEST))

# Create a new chart for the parent platform
create:
	helm create $(CHART_NAME)

# Deploy all services dynamically based on input-manifest.yaml
install:
	@echo "Installing services with versions from $(INPUT_MANIFEST)..."
	@for service in $(SERVICES); do \
		version=$$(yq eval ".services.$$service" $(INPUT_MANIFEST)); \
		echo "Installing $$service with version $$version"; \
		helm upgrade --install $$service ./charts/$$service --namespace $(NAMESPACE) --set image.tag=$$version; \
	done

# Alternative install using Make's foreach function
install-alt:
	$(foreach service, $(SERVICES), \
		helm upgrade --install $(service) ./charts/$(service) --namespace $(NAMESPACE) --set image.tag=$(shell yq eval ".services.$(service)" $(INPUT_MANIFEST)) ; \
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

update:
	helm upgrade $(CHART_NAME) ./$(FOLDER_NAME) --namespace $(NAMESPACE)

# Update all the services (e.g., after modifying values.yaml or versions)
update-all:
	$(foreach service, $(SERVICES), \
		helm upgrade $(service) ./charts/$(service) --namespace $(NAMESPACE) --set image.tag=$(shell yq eval ".services.$(service)" $(INPUT_MANIFEST)) \
	)

gh-pages-publish:
	@echo "Publishing Helm chart for $(CHART_NAME) to GitHub Pages..."
	rm -rf /tmp/gpsd-* /tmp/index.yaml
	helm package ./$(FOLDER_NAME) -d /tmp
	helm repo index /tmp --url https://$(REMOTE_CHART_REPOSITORY)/$(FOLDER_NAME)/ --merge /tmp/index.yaml
	git checkout gh-pages
	cp /tmp/index.yaml .
	git add .
	git commit -m "fix: commit to update GitHub Pages"
	git push origin gh-pages -f
	sleep 2
	curl -k https://$(REMOTE_CHART_REPOSITORY)/$(FOLDER_NAME)/index.yaml