#!/bin/bash

######################################################################
# Install Tanzu Application Platform Prework and Tanzu CLI on Linux
# Update Variables section with your information
# Execute script using sudo ./tap-preinstall.sh
# Script is offered “as-is”, without warranty, and disclaiming liability for damages resulting from using the projects
######################################################################


#########
# Update API Token, Tanzu Network User and Password with your information.  The Install Bundle, Registry and TAP Version may need to be changed as new versions are released
########

export PIVNET_API_TOKEN=[redacted]
export TANZU_NETWORK_USER=[redacted]
export TANZU_NETWORK_PASSWORD="[redacted]"
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:54bf611711923dccd7c7f10603c846782b90644d48f1cb570b43a082d18e23b9
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export TAP_VERSION=1.3.2
export INSTALL_REGISTRY_USERNAME=[redacted]
export INSTALL_REGISTRY_PASSWORD="[redacted]"
########
# Should not need to change below this line unless ELUA versions change that you need to accept and pivnet cli version changes
#######


# Get Pivnet CLI

echo Downloading Pivnet CLI
wget wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
for file in pivnet-linux*
do
    chmod ugo+x "$file"
    mv "$file" /usr/local/bin/pivnet
done

# Login to Tanzu Network and accept EULAs

echo Login to Pivnet and accept EULA
pivnet login --api-token $PIVNET_API_TOKEN
pivnet accept-eula  --product-slug='tanzu-cluster-essentials' --release-version='1.3.0'
pivnet accept-eula  --product-slug='tanzu-application-platform' --release-version='1.3.2'
pivnet accept-eula  --product-slug='build-service' --release-version='1.7.2'
pivnet accept-eula  --product-slug='tbs-dependencies' --release-version='100.0.379'

# Clean up old version

read -p "Do You want to remove any old versions of Tanzu CLI or utilites (USE WITH CAUTION)?  y/n" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

echo "Cleaning Up ond Tanzu CLI Installation"
rm -rf $HOME/tanzu/cli
rm /usr/local/bin/tanzu
rm -rf ~/.config/tanzu/
rm -rf ~/.tanzu/
rm -rf ~/.cache/tanzu
rm -rf ~/Library/Application\ Support/tanzu-cli/* # Remove plug-ins

fi

# Override directory ownership due to use of SUDO
echo "Setting Username to use to override gunzip and untar of tanzu cli bundle so its not owned by root"
un=`logname`
echo $un

# Install Tanzu Cluster Essentials

echo Downloading Tanzu Cluster Essentials
pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.3.0' --product-file-id=1330470

echo Untar Tanzu Cluster Essentials
sudo -u $un mkdir -p "$HOME/tanzu-cluster-essentials"
for file in tanzu-cluster-essential*.tgz
do
    sudo -u $un tar -zxvf "$file" -C $HOME/tanzu-cluster-essentials
done


echo Installing Tanzu Cluster Essentials
export INSTALL_BUNDLE=$INSTALL_BUNDLE
export INSTALL_REGISTRY_HOSTNAME=$INSTALL_REGISTRY_HOSTNAME
export INSTALL_REGISTRY_USERNAME=$TANZU_NETWORK_USER
export INSTALL_REGISTRY_PASSWORD=$TANZU_NETWORK_PASSWORD
cd $HOME/tanzu-cluster-essentials

# Display current kubernetes context
echo --------------------------
sudo -u $un kubectl config current-context
echo --------------------------
read -p "Is the correct Kubernetes Cluster selected (y/N)"  -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
     echo Running Tanzu Cluster Essentials Install Script
     cd $HOME/tanzu-cluster-essentials
     ./install.sh
else
     echo Please Use kubectl config use-context to set the correct cluster to install TAP on and re-run script
     exit 0
fi

# Copy Kapp binary
echo Copying kapp to /usr/local/bin
cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp

# Download Tanzu Application Platform Tanzu CLI
echo Downloading Tanzu Application Platform
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.3.2' --product-file-id=1352407

# Make Tanzu Directory and untar Tanzu Application Platform
sudo -u $un mkdir $HOME/tanzu
for file in tanzu-framework-linux*.tar
do
    sudo -u $un tar -xvf "$file" -C $HOME/tanzu
done


# Install Tanzu CL

printf 'Installing Tanzu CLI and Plugins.........'
(while :; do for c in / - \\ \|; do printf '%s\b' "$c"; sleep 1; done; done) &

      export TANZU_CLI_NO_INIT=true
      cd $HOME/tanzu
      tanzuversion=`ls -ld -- cli/core/*/ | awk '{print $9}'`
      echo "Installling tanzu cli $tanzuversion to /usr/local/bin"
      install $tanzuversion/tanzu-core* /usr/local/bin/tanzu

# Install Plugins
      sudo -u $un tanzu plugin install --local cli all

# Verify plugins
echo "Listing Installed Tanzu Plugins"
sudo -u $un tanzu plugin list

{ printf '\n'; kill $! && wait $!; } 2>/dev/null
echo Plugin job complete

# Install Tanzu Application Package

echo Installing Tanzu Application Package on cluster
echo Creating Namespace
kubectl create ns tap-install
echo Creating Registry Secret
tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install
echo Adding TAP Package Repository to cluster
tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:$TAP_VERSION \
  --namespace tap-install
echo Verify TAP Repository
tanzu package repository get tanzu-tap-repository --namespace tap-install
echo List Available Packages
tanzu package available list --namespace tap-install
echo Prep work is complete.  You are now ready to install TAP!!!