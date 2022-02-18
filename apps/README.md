# Installing Applications on Tanzu Application Platform

Once TAP has been installed you can install a test application using some of the build in accelerators

## Prep Developer Namespace

1. Create namespace for applications
`kubectl create ns apps`
2. Create required role, rolebindings, registry secret, etc using the [documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-components.html#set-up-developer-namespaces-to-use-installed-packages-46)
3. Create registry secret example
`kubectl create secret docker-registry registry-credentials --docker-server=harbor.example.com --docker-username=tapuser --docker-password=‘[redacted]’ -n apps`

## Install App using Accelerators

### Local Install Option

1. Download and unzip app bundle from accelerators tab in tap-gui
2. If you are using a JAVA (maven) app you may need to chmod +x on mvnw* files in app directory
3. docker login to your registry
4. Deploy app
`- tanzu apps workload create tanzu-java-web-app --local-path . --source-image harbor.vtechk8s.com/tap/tanzu-java-web-app-source --namespace apps --app tanzu-java-web-app --type web --yes  --live-update=true --dry-run (OPTIONAL)`
5. Check Workload Status
```
k get workload tanzu-java-web-app -n apps
k get workload tanzu-java-web-app -n apps
k get image.kpack.io/tanzu-java-web-app -n apps
k get image.kpack.io/tanzu-java-web-app -n apps -oyaml
k get route -n apps (shows endpoint based on cnrs domain_name in tap-values.yaml (also need contour installed in tap-values.yaml
```
6. Test app using output from get route
```
user@cli-vm:~/tap$ k get route -n apps
NAME                 URL                                                READY   REASON
tanzu-java-web-app   http://tanzu-java-web-app.apps.cnrs.example.com   True
```


