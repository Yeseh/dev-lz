.PHONY: build-all
build-all: build-dc

.PHONY: deploy-dc
deploy-dc:
	az deployment sub create -l westeurope -f deployments\dev-center\main.bicep -p deployments\dev-center\parameters.json

new-catalog-item:
	mkdir "catalog/new-catalog-item"
	@echo targetScope = 'subscription'> "catalog/new-catalog-item/main.bicep"
	@echo name: new-catalog-item> "catalog/new-catalog-item/manifest.yml"
	@echo version: 1.0.0>> "catalog/new-catalog-item/manifest.yml"
	@echo summary: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo description: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo runner: ARM>> "catalog/new-catalog-item/manifest.yml"
	@echo templatePath: azuredeploy.json>> "catalog/new-catalog-item/manifest.yml"