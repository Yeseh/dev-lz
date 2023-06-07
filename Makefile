DEVCENTER = dc-devlz
PROJECT = project-devlz
RG = rg-devlz
CATALOG = Catalog-devlz
ENVDEF = dotnet-function-app
ENVNAME = fnappdcdemo1

build-catalog: build-dotnet-function-app

build-dotnet-function-app:
	cd "catalog/dotnet-function-app" && az bicep build -f main.bicep --outfile azuredeploy.json 

.PHONY: deploy-dc
deploy-dc:
	az deployment sub create -l westeurope -f deployments\dev-center\main.bicep -p deployments\dev-center\parameters.json 

.PHONY: whatif-dc
whatif-dc:
	az deployment sub create -l westeurope -f deployments\dev-center\main.bicep -p deployments\dev-center\parameters.json --what-if

.PHONY: list-catalog-items
list-catalog-items:
	az devcenter dev environment-definition list --dev-center $(DEVCENTER) --project $(PROJECT) -o table

.PHONY: list-environment-types
list-environment-types:
	az devcenter dev environment-type list --dev-center $(DEVCENTER) --project-name $(PROJECT) -o table

.PHONY: sync-catalog
sync-catalog:	
	az devcenter admin catalog sync --dev-center $(DEVCENTER) --name $(CATALOG) --resource-group $(RG)

.PHONY: create-env
create-env:
	az devcenter dev environment create --catalog-name $(CATALOG)  --dev-center $(DEVCENTER)  --project $(PROJECT) --environment-type dev --environment-name $(ENVNAME) --environment-definition-name $(ENVDEF)

.PHONY: delete-env
delete-env:
	az devcenter dev environment delete --catalog-name $(CATALOG)  --dev-center $(DEVCENTER)  --project $(PROJECT) --environment-type dev --environment-name $(ENVNAME) --environment-definition-name $(ENVDEF)

new-catalog-item:
	mkdir "catalog/new-catalog-item"
	@echo targetScope = 'subscription'> "catalog/new-catalog-item/main.bicep"
	@echo name: new-catalog-item> "catalog/new-catalog-item/manifest.yml"
	@echo version: 1.0.0>> "catalog/new-catalog-item/manifest.yml"
	@echo summary: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo description: New Catalog Item>> "catalog/new-catalog-item/manifest.yml"
	@echo runner: ARM>> "catalog/new-catalog-item/manifest.yml"
	@echo templatePath: azuredeploy.json>> "catalog/new-catalog-item/manifest.yml"