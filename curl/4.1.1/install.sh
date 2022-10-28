#!/bin/bash

#set -x
echo ""
echo ""
echo "             ██    ███████    ██████               █████     ██████      ██████      ██████           "
echo "   ▄ ██ ▄    ██    ██         ██   ██             ██   ██    ██   ██    ██          ██    ██    ▄ ██ ▄"
echo "    ████     ██    ███████    ██   ██    █████    ███████    ██████     ██   ███    ██    ██     ████ "
echo "   ▀ ██ ▀    ██         ██    ██   ██             ██   ██    ██   ██    ██    ██    ██    ██    ▀ ██ ▀"
echo "             ██    ███████    ██████              ██   ██    ██   ██     ██████      ██████           "
echo "                                                                                                      "
echo "-------------------------------------"
echo "           Pre Installation          "
echo "-------------------------------------"
echo "Please Specify the required data for installation ...."
echo "---"
## Read Version
#echo -n "Specify ISD Version: "
#while read isdversion; do
#  test "$isdversion" = "" && echo "Not specified verison considering latest......" && echo "" &&  break
#  echo ""
#  break
#done

## Read Namespace
echo -n "Specify Namespace: "
while read isdnamespace; do
  test "$isdnamespace" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Namespace : "
done

## Read isd ui url
echo -n "Specify ISD-UI URL: "
while read isduiurl; do
  test "$isduiurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ISD-UI URL: "
done

## Read Argocd url
echo -n "Specify ArgoCD URL: "
while read argocdurl; do
  test "$argocdurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoCD URL: : "
done
## Read ArgoWorkflow url
#echo -n "Specify ArgoWorkflow URL: "
#while read argowrkurl; do
#  test "$argowrkurl" != "" && echo "" && break
#  echo "              INFO: ANSWER CANNOT BE BLANK!"
#  echo ""
#  echo -n "Your ArgoWorkflow URL: : "
#done

## Read ArgoRollout url
echo -n "Specify ArgoRollout URL: "
while read argoroll; do
  test "$argoroll" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoRollout URL: : "
done
echo "---"

echo "Checking for dependency......"
## check kubectl 
kubectl version > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "Kubectl present in server.."
else
  echo "ERROR: kubectl not installed ..."
  exit 1
fi
## check Helm
helm version > /dev/null 2>&1
if [ $? == 0 ];
then
        echo "Helm present in server.."
else
        echo "ERROR: Helm not installed ..."
        exit 1
fi

## install yq
yq --version > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "yq present in server.."
else
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 > /dev/null 2>&1
  chmod a+x /usr/local/bin/yq
  echo "Installed yq dependency"
fi

rm -rf values.yaml
## Override the vaules.yaml
curl -o values.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/main/charts/isdargo/values.yaml 2> /dev/null
## replacing the urls
sed -i "s/oes.example.ops.com/$isduiurl/g" values.yaml
sed -i "s/cd.ryzon7-argo22.opsmx.org/$argocdurl/g" values.yaml
#sed -i "s/workflow.ryzon7-argo22.opsmx.org/$argowrkurl/g" values.yaml
sed -i "s/rollouts.ryzon7-argo22.opsmx.org/$argoroll/g" values.yaml

##skip Crd's installtion

kubectl get CustomResourceDefinition analysisruns.argoproj.io  > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "Existing CRD's analysisruns.argoproj.io"
  yq e -i '.argo-rollouts.installCRDs = false' values.yaml
else
  echo "CRD's analysisruns.argoproj.io not present will be installed..."
  yq e -i '.argo-rollouts.installCRDs = true' values.yaml
fi

#kubectl get CustomResourceDefinition eventbus.argoproj.io  > /dev/null 2>&1
#if [ $? == 0 ];
#then
#        echo "Existing CRD's eventbus.argoproj.io"
#        yq e -i '.argo-events.crds.install = false' values.yaml
#        #yq e -i '.argo-events.crds.install = false' values.yaml
#else
#        echo "CRD's analysisruns.argoproj.io not present...."
#        yq e -i '.argo-events.crds.install = true' values.yaml
#fi


### Check and replace the install argocd, rollouts as true
yq e -i '.installArgoCD = true' values.yaml
yq e -i '.installArgoRollouts = true' values.yaml
#yq e -i '.installArgoEvents = true' values.yaml
yq e -i '.installationMode = "OEA-AP"' values.yaml
yq e -i '.installdemoapps = true' values.yaml
#yq e -i '.autoconfigureagent = true' values.yaml
echo "-------------------------------------"
echo "             Installation     "
echo "-------------------------------------"
## Helm repo add
echo "Adding the helm repo...."
helm repo add isdargo https://opsmx.github.io/enterprise-argo/
echo "Updating the helm repo ..."
helm repo update > /dev/null
## Create Namespace
echo "Creating the Namespace ..."
kubectl create namespace $isdnamespace
if [ $? == 0 ];
then
        echo ""
else
       echo "Namespace already exists.."
       echo -n "Specify Namespace: "
       while read isdnamespace; do
          test "$isdnamespace" != "" && kubectl create namespace $isdnamespace && break
          echo "              INFO: ANSWER CANNOT BE BLANK!"
          echo ""
          echo -n "Your Namespace : "
       done
fi
echo "Installing..."
echo ""
#helm install isdargo isdargo/isdargo -f values.yaml -n $isdnamespace
helm install isdargo$isdnamespace isdargo/isdargo -f values.yaml --version 4.1.0 --namespace $isdnamespace
if [ $? == 0 ];
then
  echo "-------------------------------------"
  echo "             Post Installation       "
  echo "-------------------------------------"
  echo "ISD services to be stabilize"
  wait_period=0
  while true
  do
    kubectl get po -n $isdnamespace -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > /tmp/inst.status
    ## AUTOPILOT
    SAPOR=$(grep oes-sapor /tmp/inst.status | awk '{print $2}')
    PLATFORM=$(grep oes-platform /tmp/inst.status | awk '{print $2}')
    AUTOPILOT=$(grep oes-autopilot /tmp/inst.status | awk '{print $2}')
    ARGOSERVER=$(grep argocd-server /tmp/inst.status | awk '{print $2}')
    wait_period=$(($wait_period+10))
    READYBASIC=$([ "$ARGOSERVER" == "true" ] && [ "$SAPOR" == "true" ] && [ "$PLATFORM" == "true" ] && [ "$AUTOPILOT" == "true" ]; echo $(($? == 0)) )
    READY=$READYBASIC
    if [ $READY == 1 ];
    then
        echo "       ISD services are Up and Ready.."
        echo ""
        sleep 5
        echo "           ....Installation Completed Sucessfully...."
        echo ""
        echo "       Access the ISD    --> https://$isduiurl"
        echo ""
        echo "       Access the ArgoCD --> https://$argocdurl"
        echo ""
        echo "       Access the ArgoCD --> https://$argoroll"
        echo ""
        echo "       Login with Openldap Credentials"
        echo ""
        echo "                           Username: admin"
        echo "                           Password: opsmxadmin123"
        echo "      ---------------------------------------------------------"
        break
    else
        if [ $wait_period -gt 2000 ];
        then
            echo \"      Script is timed out as the ISD is not ready yet.......\"
            break
        else
            echo "       Waiting for ISD services to be ready"
            kubectl get po -n $isdnamespace | egrep 'ContainerStatusUnknown|CrashLoopBackOff|Evicted' | awk '{print $1}' | xargs kubectl delete po -n $isdnamespace > /dev/null 2>&1
            sleep 1m
        fi
    fi
  done
else
  echo "ERROR: helm installation failed..."
  exit 1
fi
