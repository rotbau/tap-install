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

