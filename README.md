# TAP Install

VMware Tanzu Application Platform is a modular, application-aware platform that provides a rich set of developer tooling and a prepaved path to production to build and deploy software quickly and securely on any compliant public cloud or on-premises Kubernetes cluster

## Official Install Documentation

Note this repo is meant to supplement the [Official VMware documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/index.html) for installing TAP.  Always reference the official documentation

## Prerequisites
- Kubernetes cluster running compliant Kubernetes versions 1.22, 1.23 or 1.24
- Set kubectl context to cluster you want TAP installed on `kubectl config use-context {cluster}`
- Github, Gitlab or Azure Devops
- Available Registry (Docker hub, Harbor, jFrog, etc)
- DNS records for tap-gui.fqdn.com and *.cnrs.fqdn.com
- Pivnet login and/or API key
- Ability to access registry.tanzu.vmware.com (Note VMware suggests you relocate images to a registry you control and this is covered in the install documentation.)

All Commands below are for Linux.  You can find MacOS and Windows (where available) commands on official docs

## Optional Script for Linux

- The tap-preinstall-x-x-x.sh script will handle installing tanzu-cluster-essentials, Tanzu CLI, and Tanzu Application Packages.  It does not install Tanzu Application Platform.  Script was tested on linux and may need to be adjusted for macos.
- Final Install of Tanzu Application Platform is done manually and is detailed in [Install of Tap Profile and Tap section](#install-tap-profile-and-tap).  You will need to create a values.yaml file and run the final TAP install.  Skip down to [Install of Tap Profile and TAP section](#install-tap-profile-and-tap) after the script completes.

### Using Script
- Update Variables section of the script with the appropriate values
- Execute the script using sudo `sudo ./tap-preinstall-x-x-x.sh`

## Manual Prep Steps if not using script - updated for 1.3.2

### Download Pivnet CLI to accept EULA and download packages (can also download from network.pivotal.com)

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

### Download and Install Tanzu CLI

Note: Tanzu CLI for Tanzu Application Platform may conflict with other version of Tanzu CLI used for TKG.  You may want to use a separate jumpbox or profile for TAP.  [See how to remove other versions](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-uninstall.html#remove-tanzu-cli) of Tanzu CLI, Plug-ins and files.  If you are updating from an older version of TAP [reference here](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#cli-plugin-clean-install) to see how to update CLI

1. Download Tanzu CLI for your OS. 
`pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.3.2' --product-file-id=1352407`
2. Install CLI
```
mkdir $HOME/tanzu
tar -xvf tanzu-framework-linux-amd64.tar -C $HOME/tanzu
export TANZU_CLI_NO_INIT=true
cd $HOME/tanzu
export VERSION=v0.25.0
sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu
```
3. Confirm Versions
`tanzu version`  expected output is version: v0.25.0
4. Install Plugins
```
cd $HOME/tanzu
tanzu plugin install --local cli all
tanzu plugin list
```
5. Validate Plugins (for v1.3.2 output will look like this).  Note if you have TKG clusters in the same environment you will see the plugins for TKG listed as installed as well.
```
tanzu plugin list
  NAME                DESCRIPTION                                                                       SCOPE       DISCOVERY  VERSION  STATUS
  login               Login to the platform                                                             Standalone  default    v0.25.0  not installed
  management-cluster  Kubernetes management-cluster operations                                          Standalone  default    v0.25.0  not installed
  package             Tanzu package management                                                          Standalone  default    v0.25.0  installed
  pinniped-auth       Pinniped authentication operations (usually not directly invoked)                 Standalone  default    v0.25.0  not installed
  secret              Tanzu secret management                                                           Standalone  default    v0.25.0  installed
  telemetry           Configure cluster-wide telemetry settings                                         Standalone  default    v0.25.0  not installed
  accelerator         Manage accelerators in a Kubernetes cluster                                       Standalone             v1.3.1   installed
  apps                Applications on Kubernetes                                                        Standalone             v0.9.0   installed
  insight             post & query image, package, source, and vulnerability data                       Standalone             v1.3.4   installed
  services            Explore Service Instance Classes, discover claimable Service Instances and        Standalone             v0.4.0   installed
                      manage Resource Claims
```

### Install Cluster Essentials for Tanzu

1. Navigate to Tanzu Network (pivnet) and download cluster essentials or use the pivnet CLI
` pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.3.0' --product-file-id=1330470`
2. Unpack and install
```
mkdir $HOME/tanzu-cluster-essentials
tar -xvf DOWNLOADED-CLUSTER-ESSENTIALS-BUNDLE -C $HOME/tanzu-cluster-essentials
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:54bf611711923dccd7c7f10603c846782b90644d48f1cb570b43a082d18e23b9
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=TANZU-NET-USER
export INSTALL_REGISTRY_PASSWORD=TANZU-NET-PASSWORD
cd $HOME/tanzu-cluster-essentials
./install.sh --yes
```
3. Install Kapp CLI to your path
`sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp`

### Install Tanzu Application Packages
1. Add TAP package repository and version.
```
export INSTALL_REGISTRY_USERNAME=tanzunetuser@example.com
export INSTALL_REGISTRY_PASSWORD=tanzunetpassword
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export TAP_VERSION=1.0.1


export INSTALL_REGISTRY_USERNAME=tanzunetuser@example.com       #if using online install.  May be your local registry credentials 
export INSTALL_REGISTRY_PASSWORD=tanzunetpassword               #if using online install.  May be your local registry credentials 
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com      #if using online install.  This could also be your registry if you relocated images
export TAP_VERSION=1.3.2
export INSTALL_REPO=TARGET-REPOSITORY
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
for online vmware repo use:
tanzu package repository add tanzu-tap-repository \
  --url ${INSTALL_REGISTRY_HOSTNAME}/tanzu-application-platform/tap-packages:$TAP_VERSION \
  --namespace tap-install

If you have relocated images to your own registry instead of using the online registry the command will be
tanzu package repository add tanzu-tap-repository \
  --url ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages:$TAP_VERSION \
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
VERSION:       1998265
REPOSITORY:    registry.tanzu.vmware.com/tanzu-application-platform/tap-packages
TAG:           1.3.2
STATUS:        Reconcile succeeded
REASON:
```
6. List available packages
`tanzu package avaiable list --namespace tap-install`

## Install TAP Profile and TAP

Tap can be installed using a Full Profile or Light Profile.  Read more about the difference and see example value.yaml, variables definitions and other helpful info in the [Documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-about-package-profiles.html)

### Customizations

I'm using the Full Profile.  My [example values.yaml](tap-full-1-3-values.yaml) contains customizations.  I will discuss these more later.
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
  ingressDomain: "example.com"
  tls:
    namespace: tap-install
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
`tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file tap-full-values.yaml -n tap-install`
2. Verify package install may take 5-10 minutes.  All should show Reconsile Succeded.  Note you may see some temp error with packages so give it some time and see if it resolves
`tanzu package installed list --namespace tap-install`


### Update existing configuration

Look at pre-requsites, may need to upgrade tanzu cli and/or cluster providers prior to moving to steps below.

1. View current install status
```
 tanzu package available list tap-gui.tanzu.vmware.com -n tap-install
```
2. Get current repository information
```
tanzu package repository get tanzu-tap-repository --namespace tap-install
```
3. Set Registry from either the value set above or to your custom registry
```
tanzu package repository add tanzu-tap-repository --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.2.1 --namespace tap-install
```
4. Run Upgrade.  Either set TAP_VERSION as variable or add something like 1.2.1
```
tanzu package installed update tap --version $TAP_VERSION -f tap-light-values.yaml -n tap-install
```

## Update LetsEncrypt Cert for Tap-Gui

1. Update certificates
```
sudo certbot certonly --manual --preferred-challenges=dns --email null@dev.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d tap-gui.vtechk8s.com
```
2. Base64 encode the fullchain.pem and privkey.pem to files
```
base64 -w 0 fullchain.pem > fullchainb64.pem
base64 -w 0 privkey.pem > privkeyb64.pem
```
3. Create Secret manifest to update existing tap-gui secret with new values
```
---
apiVersion: v1
kind: Secret
metadata:
  name: tap-gui
  namespace: tap-gui
data:
  tls.crt: "LS0tLS1CRUdJTiB.........."
  tls.key: "LS0tLS1CRUdJTiB.........."
type: kubernetes.io/tls
```

## Access Tap-GUI

1. TAP GUI should now be available from the FQDN specificed in the base url setting in values.yaml, tap-gui.example.com 

![](/assets/tap-gui.png)

## Troubleshooting

Basics are to get useful error messages from the package and pods releated to any packages that fail to reconcile and trace them back through the stack. 

### To get useful error messages
`kubectl get packageinstall PACKAGE-NAME -n tap-install -o yaml` . 

example `kubectl get packageinstall buildservice -n tap-install -o yaml`

### Get Logs Examples

```
kubectl get pods -n build-service --show-labels
kubectl logs -n build-service -l app=dependancy-update
kubectl logs deployment/dependancy-update-controller -n build-service
```
### Other Potential Useful Commands
```
kubectl get clusterbuilder
kubectl get TanzuNetDependencyUpdaters -A
```
