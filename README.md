# TAP Install

VMware Tanzu Application Platform is a modular, application-aware platform that provides a rich set of developer tooling and a prepaved path to production to build and deploy software quickly and securely on any compliant public cloud or on-premises Kubernetes cluster

## Official Install Documentation

Note this repo is meant to supplement the [Official VMware documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-intro.html) for installing TAP.  Always reference the official documentation

## Prerequisites
- Kubernetes cluster running compliant Kubernetes versions 1.20, 1.21 or 1.22
- Github, Gitlab or Azure Devops
- Available Registry (Docker hub, Harbor, jFrog, etc)
- DNS records for tap-gui.fqdn.com and *.cnrs.fqdn.com
- Pivnet login and/or API key
- Ability to access projects.registry.vmware.com

All Commands below are for Linux.  You can find MacOS and Windows (where available) commonds on official docs

## Download Pivnet CLI to accept EULA and download packages (can also download from network.pivotal.com)

1. Download Pivnet CLI from https://github.com/pivotal-cf/pivnet-cli/releases 
`wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1`
2. Extract pivnet CLI to /usr/local/bin or equivalent for your OS
3. Login to Tanzu Network (pivnet) 
`pivnet login --api-token PIVNET_API_TOKEN`
4. Accept EULA for components
```
pivnet accept-eula  --product-slug='tanzu-cluster-essentials' --release-version='1.0.0'
pivnet accept-eula  --product-slug='tanzu-application-platform' --release-version='1.0.1'
pivnet accept-eula  --product-slug='build-service' --release-version='1.4.2'
pivnet accept-eula  --product-slug='tbs-dependencies' --release-version='100.0.250'
```

## Install Cluster Essentials for Tanzu

1. Navigate to Tanzu Network (pivnet) and download cluster essentials or use the pivnet CLI
` pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.0.0' --product-file-id=1105818`
2. Unpack and install
```
mkdir $HOME/tanzu-cluster-essentials
tar -xvf DOWNLOADED-CLUSTER-ESSENTIALS-PACKAGE -C $HOME/tanzu-cluster-essentials
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=tanzunetuser@example.com
export INSTALL_REGISTRY_PASSWORD=tanzunetpassword
cd $HOME/tanzu-cluster-essentials
./install.sh
```
3. Install Kapp CLI to your path
`sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp`

## Download and Install Tanzu CLI

Note: Tanzu CLI for Tanzu Application Platform may conflict with other version of Tanzu CLI used for TKG.  You may want to use a separate jumpbox or profile for TAP.  [See how to remove other versions](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-uninstall.html#remove-tanzu-cli) of Tanzu CLI, Plug-ins and files.  If you are updating from an older version of TAP [reference here](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#cli-plugin-clean-install) to see how to update CLI

1. Download Tanzu CLI for your OS. 
`pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.0.1' --product-file-id=1147349`
2. Install CLI
```
mkdir $HOME/tanzu
tar -xvf tanzu-framework-linux-amd64.tar -C $HOME/tanzu
export TANZU_CLI_NO_INIT=true
cd $HOME/tanzu
sudo install cli/core/v0.11.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu
```
3. Confirm Versions
`tanzu version`  expected output is version: v0.11.1
4. Install Plugins
```
export TANZU_CLI_NO_INIT=true
cd $HOME/tanzu
tanzu plugin install --local cli all
tanzu plugin list
```
5. Validate Plugins (for v1.0.1 output will look like this)
```
tanzu plugin list
NAME                DESCRIPTION                                                        SCOPE       DISCOVERY  VERSION  STATUS
login               Login to the platform                                              Standalone  default    v0.11.1  not installed
management-cluster  Kubernetes management-cluster operations                           Standalone  default    v0.11.1  not installed
package             Tanzu package management                                           Standalone  default    v0.11.1  installed
pinniped-auth       Pinniped authentication operations (usually not directly invoked)  Standalone  default    v0.11.1  not installed
secret              Tanzu secret management                                            Standalone  default    v0.11.1  installed
accelerator         Manage accelerators in a Kubernetes cluster                        Standalone             v1.0.1   installed
apps                Applications on Kubernetes                                         Standalone             v0.4.1   installed
services            Discover Service Types and manage Service Instances (ALPHA)        Standalone             v0.1.1   installed
```
## Install Tanzu Application Package
1. Add TAP package repository and version.
```
export INSTALL_REGISTRY_USERNAME=tanzunetuser@example.com
export INSTALL_REGISTRY_PASSWORD=tanzunetpassword
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export TAP_VERSION=1.0.1
```
2. Create Tap namespace
`kubectl create ns tap-insall`
3. Create Registry Secret
```
tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install
```
4. Add TAP package repository to cluster
```
tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:$TAP_VERSION \
  --namespace tap-install
```
5. Verify TAP repository
```
tanzu package repository get tanzu-tap-repository --namespace tap-install
```
Expected Output similar to 
```
$ tanzu package repository get tanzu-tap-repository --namespace tap-install
| Retrieving repository tap...
NAME:          tanzu-tap-repository
VERSION:       121657971
REPOSITORY:    registry.tanzu.vmware.com/tanzu-application-platform/tap-packages
TAG:           1.0.1
STATUS:        Reconcile succeeded
REASON:
```
6. List available packages
`tanzu package avaiable list --namespace tap-install`

## Instal TAP Profile

Tap can be installed using a Full Profile or Light Profile.  Read more about the difference and see example value.yaml, variables definitions and other helpful info in the [Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install.html#install-your-tanzu-application-platform-profile-1)

### Customizations

I'm using the Light Profile.  My [example values.yaml](tap-light-values.yaml) contains customizations.  I will discuss these more later.
- Contour for Ingress
- TLS for tap-gui using Letsencrypt
- CNRS domain which will automatically be appended to my applications I publish using ingress
- OKTA integration for Authentication

1. Add Contour for Ingress
```
contour:
  envoy:
    service:
      type: LoadBalancer
```
2. TLS for tap-gui using Letsencrypt

Get Cert and base 64 encode:
```
sudo certbot certonly --manual --prefered-challanges=dns --email email@example.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d tap-gui.example.com
base64 -w 0 fullchain.pem > /home/user/tap/fullchainb64.txt
base64 -w 0 privkey.pem > /hom/user/tap/keyb64.txt
```

Create TLS Secret on K8s Cluster:
```
apiVersion: v1
kind: Secret
metadata:
  name: tap-gui
  namespace: tap-install
data:
  tls.crt: “base64 of /etc/letsencrypt/tap-gui.example.com/fullchain.pem”
  tls.key: “base64 of /etc/letsencrptlive/tap-gui.example.com/privkey.pem”
type: kubernetes.io/tls
```

Configure TAP GUI in values.yaml for TLS
```
tap_gui:
  service_type: ClusterIP
  ingressEnabled: "true"
  ingressDomain: "vtechk8s.com"
  tls:
    namespace: tap-gui
    secretName: tap-gui
```
3. CNRS entry for domain suffix and automatic Ingress to deployed Application

Note: This will need to be done AFTER Tap in installed
`kubectl get svc -n tanzu-system-ingress`
Note IP of envoy service.  This should have an IP from your Cloud Provider or LB Provider
Create a DNS record for *.cnrs.example.com pointing to this record
Published apps will have format of app.cnrs.example.com and ingress will automatically send traffic to your application
4. OKTA Configuration
- Create new application in OKTA: type=Web
- Grant Types: Client Credentials, Authorization Token, Refresh Token
- Refresh Token Behavior: I have Use Persistent Token
- User Consent: I have Require Consent
- Login - This can be mostly anything.  However you HAVE to match traffic type.  If you are using TLS this needs to start with https: or if not enabling TLS need to start with http:
```
sign-in redirect URIs https://tap-gui.example.com/api/auth/okta/handler/frame
sign-out redirect URIs https://tap-gui.example.com
```  
Have also seen https://localhost:7001/api/auth/okta/handler/frame and https://localhost:7001  These values only need to be reachable by the client browser.
- Assign users
- Client ID, Client Secret and Okta Domain from the General Tap of the Application will be used in values.yaml
```
      providers:
        okta:
          development:
            clientId: [redacted]
            clientSecret: [redacted]
            audience: https:/[redacted].okta.com
```
### Install TAP

1. After configuring your values.yaml install TAP
`tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file tap-light-values.yaml -n tap-install`
2. Verify package install may take 5-10 minutes
`tanzu package installed get tap -n tap-install`
3. Verify all necessary packages have been installed
`tanzu package installed list -A`