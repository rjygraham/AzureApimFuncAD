# Azure API Management with Azure AD secured Azure Functions Backend

This sample repo illustrates how to use Azure API Management policies to authenticate to Azure AD and invoke an Azure Functions backend secured by Azure AD.

Key concepts shown in this sample include:

1. Azure API Management [`<authentication-managed-identity>` policy](https://learn.microsoft.com/en-us/azure/api-management/api-management-authentication-policies#ManagedIdentity)
1. Azure API Management [`<set-backend-service>` policy](https://learn.microsoft.com/en-us/azure/api-management/api-management-transformation-policies#SetBackendService)
1. Securing an Azure Function using [App Service Authentication with Azure AD](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad)
1. Adding an HTTP triggered function to Azure API Management via Bicep

## Setup

After cloning this repo, setup involves the following 3 steps.

### Azure AD App Registration

Follow the instructions for Option 2 on the [Configure your App Service or Azure Functions app to use Azure AD login](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad#-option-2-use-an-existing-registration-created-separately) documentation page. Steps 1-6, 11 are all that are required for the setup.

> NOTE: You may not know the FQDN of your Azure Function App yet, so you can put `https://localhost.azurewebsites.net/.auth/login/aad/callback` for step 4

### Deploy Bicep Template

From the root of the repo, run the following Azure CLI commands:

```bash
# Substitute your preferred location and resource group name as appropriate
az group create -l eastus -n APIM-FUNC-AAD

# Value for AzureAdClientId comes from step 5 of the Azure AD App Registration section above
az deployment group create -g APIM-FUNC-AAD --template-file infra\main.bicep --parameters publisherEmail=youremail@domain.com publisherName=YourName azureAdClientId=AzureAdClientId --query '{RedirectUri:properties.outputs.redirectUri.value, ApiUri:properties.outputs.apiUri.value}'
```

You will then be prompted for `azureAdClientSecret`:
```bash
# Value for azureAdClientSecret comes from step 11 of the Azure AD App Registration section above
Please provide securestring value for 'azureAdClientSecret' (? for help):
```

### Update Azure AD App Registration Redirect URI

Refer back to Option 2 of the the [Configure your App Service or Azure Functions app to use Azure AD login](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad#-option-2-use-an-existing-registration-created-separately) documenation and update the app registration Redirect URI in Step 4 with the `RedirectUri` output value

### Usage

Use your favorite HTTP testing tool such as cURL, Postman, VS Code HTTP Client, etc to send a GET request to the `ApiUri` value in the output of `az deployment group create` command above.

For example:

```http
GET https://b3viit2zwij2tq-apim.azure-api.net/b3viit2zwij2tq-func-app/SampleHttpTriggeredFunction
```

You can also add a `name` query parameter like so:

```http
GET https://b3viit2zwij2tq-apim.azure-api.net/b3viit2zwij2tq-func-app/SampleHttpTriggeredFunction?name=Test
```