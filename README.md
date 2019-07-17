# azure-terraform-bootstrapper

## Bootstrap

Copy and paste the below into the Azure Cloud Shell.

```bash
wget https://raw.githubusercontent.com/JimPaine/azure-terraform-bootstrapper/master/bootsrapper/main.tf -O main.tf \
  && terraform init \
  && terraform apply -var="resource_group_name=terraform" -var="resource_group_location=westeurope" -auto-approve
```

## What it does

Aimed at accelerating the implementation of Terraform on Azure, this bootstrapper will;
- Create a storage account for the remote state management
- Create a Service Principal for terraform to use for CI / CD
- Give the Service Principal owner access to the subscription so it can manage resources
- Create a key vault 
- Add all the details about the service principal and the storage account as secrets in the key vault.

## Getting Started

Now your environment is ready to run terraform on Azure lets use the included template to test it out.

Go to `https://dev.azure.com` and create an account if you haven't already.

### Link to Key Vault

So we can use all the details created by the bootstrapper in a secure way, lets create a new variable group based on the key vault it created.

- Navigate to `Library`
- Create a new group
- Ensure to call it `Terraform` as this is what the pipeline will look for! - Then select `Link secrets from an Azure Key Vault as variables`
- Select the subscription and click Authorize
- Select the Key Vault and Authorize
- Select all secrets
- Save


### Import this repo

- Create a new repo and import this repo `https://github.com/JimPaine/azure-terraform-bootstrapper.git`

### Install marketplace task

- [Replace Tokens](https://marketplace.visualstudio.com/items?itemName=qetza.replacetokens)

### New pipeline

- Create a new Pipeline
- Select the repo you imported above
- It will automatically load the `azure-pipelines.yml` file
- Click `Run`

Now you are all done :) and ready for more terraforming!