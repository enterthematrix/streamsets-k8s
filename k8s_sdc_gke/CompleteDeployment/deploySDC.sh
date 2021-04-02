#!/bin/bash


SCH_PASSWORD1=$SCH_PASSWORD
SDC_DOWNLOAD_PASSWORD1=$SDC_DOWNLOAD_PASSWORD
SCH_USER1=$SCH_USER



# DELETE ME
SDC_VERSION1=3.22.0

read -p 'SCH URL[https://cloud.streamsets.com]: ' SCH_URL
SCH_URL=${SCH_URL:-https://cloud.streamsets.com}

read -p 'SCH ORG[dpmsupport]:' SCH_ORG
SCH_ORG=${SCH_ORG:-dpmsupport}

read -p 'SCH USER: ' SCH_USER
SCH_USER=${SCH_USER:-$SCH_USER1}

read -sp 'SCH PASSWORD: ' SCH_PASSWORD
SCH_PASSWORD=${SCH_PASSWORD:-$SCH_PASSWORD1}
printf "\n"

read -p 'SDC DOWNLOAD USER[StreamSets]:' SDC_DOWNLOAD_USER
SDC_DOWNLOAD_USER=${SDC_DOWNLOAD_USER:-StreamSets}

read -sp 'SDC DOWNLOAD PASSWORD: ' SDC_DOWNLOAD_PASSWORD
SDC_DOWNLOAD_PASSWORD=${SDC_DOWNLOAD_PASSWORD:-$SDC_DOWNLOAD_PASSWORD1}
printf "\n"

read -p 'SDC VERSION: ' SDC_VERSION
SDC_VERSION=${SDC_VERSION:-$SDC_VERSION1}

read -p 'Installation Type(b -basic | f -full) [b]: ' INSTALL_TYPE
INSTALL_TYPE=${INSTALL_TYPE:-b}


# Check prerequisites [ TO DO  - helm / kubectl / jq]


STREAMSETS_DOWNLOAD_URL=https://downloads.streamsets.com/datacollector
KUBE_NAMESPACE="sdc-$(echo "$SDC_VERSION" | tr . -)"


if [ -z "$SCH_USER" ]  || [ -z "$SDC_VERSION" ]
  then
      printf "No values !! \n"
      exit 1
fi

# create the Kubernetes cluster on GKE
gcloud container clusters delete $USER-$KUBE_NAMESPACE
gcloud container clusters create $USER-$KUBE_NAMESPACE \
    --num-nodes=1 \
    --machine-type=e2-standard-2 \
    --zone=us-central1-c

# gcloud container clusters delete  sanju-sdc-3-18-1
# create a brand new namespace to isolate all the resources for this deployment
kubectl create namespace $KUBE_NAMESPACE

# validate namespace
if [[ $(kubectl get namespaces $KUBE_NAMESPACE | awk 'FNR == 2 {print $1}') != $KUBE_NAMESPACE ]]
  then
    printf "Failed to create the Kubernetes namespace !! \n"
    exit 0;
  else
    kubectl config set-context --current --namespace $KUBE_NAMESPACE
    if [[ $(kubectl config view --minify | grep namespace | awk '{print $2}') != $KUBE_NAMESPACE ]]
      then
        printf "Failed to set context to $KUBE_NAMESPACE namespace !! \n"
    fi
fi

# Generate ssl key-pair:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout sdc.key -out sdc.crt -subj "/CN=auth-sdc/O=auth-sdc"

# Store the cert in a k8's secret
kubectl create secret generic sdc-tls --namespace=${KUBE_NAMESPACE} \
    --from-file=sdc.crt \
    --from-file=sdc.key

# create configmap for environment variables
kubectl create configmap sdc-deployment-config \
 --from-literal SCH_URL=$SCH_URL \
 --from-literal SCH_ORG=$SCH_ORG \
 --from-literal SCH_USER=$SCH_USER \
 --from-literal SDC_DOWNLOAD_USER=$SDC_DOWNLOAD_USER \
 --from-literal SDC_VERSION=$SDC_VERSION \
 --from-literal STREAMSETS_DOWNLOAD_URL=$STREAMSETS_DOWNLOAD_URL

# Create secrets to secure the passwords
 kubectl create secret generic sdc-deployment-secret \
  --from-literal SCH_PASSWORD=$SCH_PASSWORD \
  --from-literal SDC_DOWNLOAD_PASSWORD="${SDC_DOWNLOAD_PASSWORD}"

# Store the SDC auth token in a secret
kubectl create secret generic sdc-auth-token --from-literal=application-token.txt=${SDC_AUTH_TOKEN}

# Test download job
# echo $STREAMSETS_DOWNLOAD_URL
# echo $SDC_DOWNLOAD_USER
# echo $SDC_DOWNLOAD_PASSWORD
# echo $SDC_VERSION
# wget --user=$SDC_DOWNLOAD_USER --password="${SDC_DOWNLOAD_PASSWORD}" ${STREAMSETS_DOWNLOAD_URL}/${SDC_VERSION}/tarball/streamsets-datacollector-all-${SDC_VERSION}.tgz

# install NGINX ingress controller
helm install $KUBE_NAMESPACE stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true --namespace=$KUBE_NAMESPACE

if [[ "$INSTALL_TYPE" == "f" ]]
  then
      #  Create the Volume to store SDC stagelibs.
      kubectl apply -f sdc-pvc.yaml
      #  Run a Job to download all the stagelibs and populate the K8's volume
      kubectl apply -f sdcDownloadJob.yaml
      # update SDC specs to have SDC hostanme start with the username
      sed -i -e  's/latest/'"$SDC_VERSION"'/' sdcFullDeployment.yaml
      # update SDC specs with $SDC_VERSION
      sed -i -e  's/sanju-sdc-gke/'"$USER"'-sdc-gke/' sdcFullDeployment.yaml

      # Deploy the SDC pod
      kubectl apply -f sdcFullDeployment.yaml

      # Reset the specs with the defaults for next run
      sed -i -e  's/'"$SDC_VERSION"'/latest/' sdcFullDeployment.yaml
      sed -i -e  's/'"$USER"'-sdc-gke/'"sanju-sdc-gke"'/' sdcFullDeployment.yaml
  else
      # update SDC specs with $SDC_VERSION
      sed -i -e  's/latest/'"$SDC_VERSION"'/' sdcDeployment.yaml
      # update SDC specs to have SDC hostanme start with the username
      sed -i -e  's/sanju-sdc-gke/'"$USER"'-sdc-gke/' sdcDeployment.yaml

      # Deploy the SDC pod
      kubectl apply -f sdcDeployment.yaml

      # Reset the specs with the defaults for next run
      sed -i -e  's/'"$SDC_VERSION"'/latest/' sdcDeployment.yaml
      sed -i -e  's/'"$USER"'-sdc-gke/'"sanju-sdc-gke"'/' sdcDeployment.yaml
fi
