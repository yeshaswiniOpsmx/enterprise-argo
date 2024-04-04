<p align="center">
	<img src="https://github.com/OpsMx/enterprise-argo/blob/main/img/opsmx.png" width="20%" align="center" alt="OpsMx">
</p>

# OpsMx Enterprise for Argo

For more information, visit https://www.opsmx.com
	
## Setup Instructions

### Prerequisites

- Kubernetes cluster 1.20 or later with at least 4 cores and 16 GB memory
- Helm 3 is setup on the client system with 3.10.3 or later
- Ensure that this URLs(ISD,KeyCloak,Vela) is reachable from your browser. Either DNS name server record must exist or "hosts" file must be updated.The following 3 URLs need to be exist in DNS and point to Loadbalancer IP of the nginx ingress controller.

	```console
	Ip-address ISD.REPLACE.THIS.WITH.YOURCOMPANY.COM

	Ip-address KEYCLOAK.REPLACE.THIS.WITH.YOURCOMPANY.COM
	
	Ip-address *.VELA.REPLACE.THIS.WITH.YOURCOMPANY.COM
	```
	`E.g.: isd.isd-argo.opsmx.com`

- Vela Service requires the “Wild-card ingress” and “Wild-card TLS certificates to be provided to the ingress”

  Please use below blog to create a Wild-card TLS certificates to provide for the Ingress, if you are using the cert-manager.

  https://www.linkedin.com/pulse/wildcard-certificates-using-lets-encrypt-certbot-pallavi-udhane/
  
  Else please contact your certificate provider for the certificates for your URL equivalent for `"*.VELA.REPLACE.THIS.WITH.YOURCOMPANY.COM"`

- An additional host URL may be required depending on your requirements. See below for instructions
	- controller host url and/or
	- ArgoCD host url

- Use below command to check if helm is installed or not
        
   ```console
   helm version
   ```
  If helm is not setup, follow <https://helm.sh/docs/intro/install/> to install helm.

### Installation Instructions

- Add opsmx helm repo to your local machine

   ```console
   helm repo add isdargo https://opsmx.github.io/enterprise-argo/
   ```

  Note: If opsmx helm repo is already added, do a repo update before installing the chart

   ```console
   helm repo update
   ```

- Your Kubernetes cluster should support persistent volumes

- It is assumed that an nginx ingress controller is installed on the cluster, by default ingress resources are created for oes-ui, keycloak, vela and argocd services. Customize the hosts for various installations using the options in the values.yaml under oesUI, keycloak, vela, argo-cd. If any other ingress controller is installed, set createIngress flag to false and configure your ingress.

  Instructions to install nginx ingress
  https://kubernetes.github.io/ingress-nginx/deploy/

  Instructions to install cert-manager
  https://cert-manager.io/docs/installation/kubernetes/

- Helm v3 expects the namespace to be present before helm install command is run. If it does not exists,

  ```console
  kubectl create namespace opsmx-argo
  ```
- There are different flavours of Installations

    Values yamls    | Description 
  --------------| ----------- 
  isd-minimal-values.yaml | This file is used for Installing only ISD without Argo CD and Argo Rollouts
  isd-argo-minimal-values.yaml | This file is used for Installing ISD,Argo CD and Argo Rollouts
  isd-rollouts-values.yaml | This file is used for Installing ISD and Argo Rollouts without Argo CD
  onlyargorollouts-values.yaml | This file is used for Installing only Argo Rollouts without Argo CD and ISD
  argocd-rollouts-values.yaml | This file is used for Installing Argo CD and Argo Rollouts without ISD

**NOTE**: In all the values.yaml please read inline comments and update it accordingly.

#### Install ISD

- Update forwarder.externalName URL in isd-minimal-values.yaml. The actual DNS needs to be created/updated after installation 
- Use below command to install ISD using the helm chart:

  ```console
  helm install isd isdargo/isdargo -f isd-minimal-values.yaml -n opsmx-argo --timeout 15m
  ```
- Please create/update the DNS based on the loadbalancer created using instructions here: https://docs.google.com/document/d/1cahEx4NihwRyqZtFijTJ79Zxe8_PixuKrosAocxSIrk/edit#
- Create vela-ingress tls secret using the wild-card certificate and key
 e.g. kubectl create secret tls vela-ingress -n opsmx-argo --cert cert1.pem --key privkey1.pem

#### Install ISD-ARGO

- OPTIONAL: Update forwarder.externalName URL in isd-argo-minimal-values.yaml. The actual DNS needs to be created after installation 
- Apart of above 3 urls update the Argo CD Url in the DNS name server record must exist or "hosts" file must be updated.

	```console
	Ip-address ARGO.REPLACE.THIS.WITH.YOURCOMPANY.COM
	```

- Use below command to install ISD-ARGO using the helm chart:

  ```console
  helm install isdargo isdargo/isdargo -f isd-argo-minimal-values.yaml -n opsmx-argo --timeout 15m
  ```
- OPTIONAL: Please create/update the DNS based on the loadbalancer created using instructions here: https://docs.google.com/document/d/1cahEx4NihwRyqZtFijTJ79Zxe8_PixuKrosAocxSIrk/edit#
- Create vela-ingress tls secret using the wild-card certificate and key
 e.g. kubectl create secret tls vela-ingress -n opsmx-argo --cert cert1.pem --key privkey1.pem

NOTE: The OPTIONAL steps above can be done after the installation at a later point, if required by following all the steps in the document.

> **Tip**: List all releases using `helm list`

### Troubleshooting
1. Everything installed but I don't see any applications.
- If "full" installed is used (i.e. isd-argo-minimal-values.yaml), it automatically installs sample applications, including a working rollouts sample.
- If connecting to an existing argo or adding a new argo, please ensure that the user-token generated has admin RBAC permissions.

2. Clicking on an application in Home-screen takes me to a blank page or a page with an error
- Vela service needs wild-card DNS and wild-card TLS certificates for this work due to restrictions in ArgoCD.
- We can test it by opening another tab in the browser and putting going to "isd.VELA.REPLACE.THIS.WITH.YOURCOMPANY.COM", it should load and say "Failed to load".

## After installation, Follow the steps in Token-Generation-And-Rotation Folder for Generating a new token
- <https://github.com/OpsMx/enterprise-argo/blob/v4.1.7/Token-Generation-And-Rotation/README.md>


### Uninstall

To uninstall/delete the deployment

#### Uninstalling the ISD

  ```console
  helm uninstall isd -n opsmx-argo
  ```
#### Uninstalling the ISD-ARGO

  ```console
  helm uninstall isdargo -n opsmx-argo
  ```
