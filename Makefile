DEVCENTER = dc-devlz
PROJECT = project-devlz
RG = rg-devlz
CATALOG = Catalog-devlz

.PHONY: build-all
build-all: build-demo1

build-demo1:
	cd "catalog/demo1" && az bicep build -f main.bicep --outfile azuredeploy.json --mode complete

.PHONY: deploy-dc
deploy-dc:
	az deployment sub create -l westeurope -f deployments\dev-center\main.bicep -p deployments\dev-center\parameters.json 

.PHONY: whatif-dc
whatif-dc:
	az deployment sub create -l westeurope -f deployments\dev-center\main.bicep -p deployments\dev-center\parameters.json --what-if

.PHONY: list-catalog-items
list-catalog-items:
	az devcenter dev catalog-item list --devcenter $(DEVCENTER) --project $(PROJECT) -o table

.PHONY: list-environment-types
list-environment-types:
	az devcenter dev environment-type list --dev-center $(DEVCENTER) --project-name $(PROJECT) -o table

new-catalog-item:
	mkdir "catalog/new-catalog-item"
	@echo targetScope = 'subscription'> "catalog/new-catalog-item/main.bicep"
	@echo name: new-catalog-item> "catalog/new-catalog-item/manifest.yml"
	@echo version: 1.0.0>> "catalog/new-catalog-item/manifest.yml"
	@echo summary: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo description: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo runner: ARM>> "catalog/new-catalog-item/manifest.yml"
	@echo templatePath: azuredeploy.json>> "catalog/new-catalog-item/manifest.yml"