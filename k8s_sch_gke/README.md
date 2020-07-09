![SCH Splash Image](/images/DPM.png)

### Simple SCH deployment on GKE
Pre-req: Kubectl, Helm3, Google Cloud SDK

```bash
# Register helm char repo
1) helm repo add stable https://kubernetes-charts.storage.googleapis.com

# Install Traefik as an Ingress Controller using this command:
2) helm install traefik \
stable/traefik \
 --set rbac.enabled=true \
 --namespace kube-system
# Update DNS with the ingress external ip
3) kubectl get svc traefik --namespace kube-system -w
# Create a namespace
4) kubectl create namespace streamsets
# To pull SCH image from docker, create a docker-registry secret
5) kubectl create secret docker-registry myregistrykey \
  --namespace streamsets \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<YOUR_DOCKER_LOGIN> \
  --docker-password=<YOUR_DOCKER_PASSWORD> \
  --docker-email=<YOUR_DOCKER_EMAIL>
# Download StreamSets Helm Charts GitHub project from
6) git clone https://github.com/streamsets/helm-charts

# Get mysql help charts
7) cd ~/helm-charts
helm dependency update incubating/control-hub

# Edit the parameters for SCH install under ~/helm-charts/incubating/control-hub/charts/sch-values.yaml
# Parameter description @ https://github.com/streamsets/helm-charts/blob/master/incubating/control-hub/README.md#configuration
# Install SCH uisng Helm3:
8) helm install sch incubating/control-hub  --namespace streamsets --values sch-values.yaml

# Remove the installation
9) helm del sch -n streamsets

```

### Provisining agent deployment on GKE using helm3

```bash
# Install the agent
helm install sanju streamsets/control-agent --values control-agent.yaml

# Remove the installation
9) helm del sch -n streamsets
```
