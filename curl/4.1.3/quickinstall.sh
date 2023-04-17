#!/bin/bash

#set -x

isdlogo(){
## Chart Version 
version=4.1.2
echo ""
echo ""
echo "             ██    ███████    ██████               █████     ██████      ██████      ██████           "
echo "   ▄ ██ ▄    ██    ██         ██   ██             ██   ██    ██   ██    ██          ██    ██    ▄ ██ ▄"
echo "    ████     ██    ███████    ██   ██    █████    ███████    ██████     ██   ███    ██    ██     ████ "
echo "   ▀ ██ ▀    ██         ██    ██   ██             ██   ██    ██   ██    ██    ██    ██    ██    ▀ ██ ▀"
echo "             ██    ███████    ██████              ██   ██    ██   ██     ██████      ██████           "
echo "                                                                                                      "
echo "------------------------------------------------------------"
echo " System Requirements "
echo "------------------------------------------------------------"
echo "   Configuration with at least 4 cores and 16 GB memory"
echo "   Kubernetes cluster 1.19 or later                    "
echo "-------------------------"
read -p "Press enter to continue..."
echo ""
}

getinstallyaml(){
rm -rf curl-isd-argo-quick.yaml
## Get the vaules.yaml
curl -o curl-isd-argo-quick.yaml https://raw.githubusercontent.com/opsmx/isd-quick-install/main/isd411/curl-isd-argo-quick.yaml 2> /dev/null
}

getports(){
## Checking the available ports for ISD UI,ArgoCD and Argo Rollouts
ARGOCD_PORT=$(assignPort 9000)
#echo $ARGOCD_PORT
ISDUI_PORT=8093
#ISDUI_PORT=$(assignPort 8080)
#echo $ISDUI_PORT
ROLLOUT_PORT=$(assignPort 9100)
#echo $ROLLOUT_PORT
}

assignPort(){
currentPort=$1
if lsof -Pi :$currentPort -sTCP:LISTEN -t >/dev/null ; then
    #echo "$currentPort port is busy so calling recusive function again"
    currentPort=$((currentPort+1))
    assignPort $currentPort
else
    echo $currentPort
    return 1 
fi
}

replaceports(){

if [[ $OSTYPE == 'darwin'* ]]; then
  sed -i.bu "s/ARGOCD_PORT/$ARGOCD_PORT/g" curl-isd-argo-quick.yaml
  sed -i.bu "s/ISDUI_PORT/$ISDUI_PORT/g" curl-isd-argo-quick.yaml

else
  sed -i "s/ARGOCD_PORT/$ARGOCD_PORT/g" curl-isd-argo-quick.yaml
  sed -i "s/ISDUI_PORT/$ISDUI_PORT/g" curl-isd-argo-quick.yaml
fi
}

checkcrds(){
##skip Crd's installtion
kubectl get CustomResourceDefinition analysisruns.argoproj.io  > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "Existing CRD's analysisruns.argoproj.io"
else
  echo "CRD's analysisruns.argoproj.io not present will be installed..."
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
}

isdargoinstallation(){
echo "-------------------------------------"
echo "             Installation     "
echo "-------------------------------------"
kubectl apply -f curl-isd-argo-quick.yaml -n opsmx-argo 
}

isdargocheck() {
if [ $? == 0 ];
then
  echo "-------------------------------------"
  echo "             Post Installation       "
  echo "-------------------------------------"
  echo "ISD services to be stabilize"
  wait_period=0
  while true
  do
    rm -rf inst.status
    kubectl get po -n opsmx-argo -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > inst.status
    ## AUTOPILOT
    SAPOR=$(grep oes-sapor inst.status | awk '{print $2}')
    PLATFORM=$(grep oes-platform inst.status | awk '{print $2}')
    AUTOPILOT=$(grep oes-autopilot inst.status | awk '{print $2}')
    ARGOSERVER=$(grep argocd-server inst.status | awk '{print $2}')
    OESGATE=$(grep oes-gate inst.status | awk '{print $2}')
    AGENTCONFIG=$(grep oes-autoconfig inst.status | awk '{print $2}')
    wait_period=$(($wait_period+10))
    READYBASIC=$([ "$AGENTCONFIG" == "false" ] && [ "$OESGATE" == "true" ] && [ "$ARGOSERVER" == "true" ] && [ "$SAPOR" == "true" ] && [ "$PLATFORM" == "true" ] && [ "$AUTOPILOT" == "true" ]; echo $(($? == 0)) )
    READY=$READYBASIC
    if [ $READY == 1 ];
    then
        echo "       ISD services are Up and Ready.."
        echo ""
        sleep 3
        echo "           ....Installation Completed Sucessfully...."
	echo ""
	echo "Below are the services need to be portforwarded to Access the ISD-ARGO:"
        echo ""
        echo " ---------->  kubectl -n opsmx-argo port-forward svc/oes-ui $ISDUI_PORT & kubectl -n opsmx-argo port-forward svc/isdargo-argocd-server $ARGOCD_PORT:80 & kubectl -n opsmx-argo port-forward svc/isdargo-argo-rollouts-dashboard $ROLLOUT_PORT:3100"
        echo ""
        argopass=$(kubectl -n opsmx-argo get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
        echo ""
        echo "       ISD UI          ---> http://localhost:$ISDUI_PORT    ---> Login with admin/opsmxadmin123"
        echo ""
        echo "       ARGOCD UI       ---> http://localhost:$ARGOCD_PORT   ---> Login with admin/$argopass"
        echo ""
        echo "       ARGOROLLOUTS UI ---> http://localhost:$ROLLOUT_PORT"
        echo ""
        echo ""
        break
    else
        if [ $wait_period -gt 2000 ];
        then
            echo \"      Script is timed out as the ISD is not ready yet.......\"
            break
        else
            echo "       Waiting for ISD services to be ready"
            kubectl get po -n opsmx-argo | egrep 'ContainerStatusUnknown|CrashLoopBackOff|Evicted' | awk '{print $1}' | xargs kubectl delete po -n opsmx-argo > /dev/null 2>&1
            sleep 60
        fi
    fi
  done
else
  echo "ERROR: helm installation failed..."
  echo "ERROR: Some times it is due to timeout, Please check the pods and service...."
  exit 1
fi
}
isdlogo
getinstallyaml
getports
replaceports
#checkcrds
isdargoinstallation
isdargocheck
