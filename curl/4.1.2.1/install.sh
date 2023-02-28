#!/bin/bash

#set -x

isdlogo(){
## Chart Version 
version=4.1.2.1
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
echo "   Kubernetes cluster 1.22 or later                    "
echo "   Helm 3 is setup on the client system   Installation - https://helm.sh/docs/intro/install/"
echo "   Nginx ingress controlled installed     Installation - https://kubernetes.github.io/ingress-nginx/deploy/"
echo "   Cert-manager installed                 Installation - https://cert-manager.io/docs/installation/kubernetes/"
echo "-------------------------"
read -p "Press enter to continue..."
echo "-------------------------------------"
echo "           Pre Installation          "
echo "-------------------------------------"
echo "Please Specify the required data for installation ...."
echo ""
## Read Version
#echo -n "Specify ISD Version: "
#while read isdversion; do
#  test "$isdversion" = "" && echo "Not specified verison considering latest......" && echo "" &&  break
#  echo ""
#  break
#done
}
readmode() {
## Read Mode
echo "Installation Modes"
echo " _________________________________________________________"
echo "|         Description                    -      Mode      |"
echo "|---------------------------------------------------------|"
echo "|To install only ISD mode is             -       ISD      |"
echo "|                                                         |"
echo "|Full installation with ISD-ARGO mode is -     ISD-ARGO   |"
echo "|_________________________________________________________|"
echo ""
echo -n "Specify Mode of installation: "
while read isdmode; do
  test "$isdmode" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Mode of installation: "
done
}

readnamespace(){
## Read Namespace
echo -n "Specify Namespace: "
while read isdnamespace; do
  test "$isdnamespace" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Namespace : "
done
}
readisdurl(){
## Read isd ui url
echo -n "Specify ISD-UI URL: "
while read isduiurl; do
  test "$isduiurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ISD-UI URL:"
done
## read vela ingress

echo -n "Specify Vela URL: "
while read vela; do
  test "$vela" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Vela URL: "
done


}
readargourls(){
echo -n "Specify ArgoCD URL: "
while read argocdurl; do
  test "$argocdurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoCD URL:"
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
  echo -n "Your ArgoRollout URL:"
done
echo "---"
}

checkdep(){
echo "Checking for dependency......"
## check kubectl 
#kubectl version > /dev/null 2>&1
#if [ $? == 0 ];
#then
#  echo "Kubectl present in server.."
#else
#  echo "ERROR: kubectl not installed ..."
#  exit 1
#fi
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
   if [[ $OSTYPE == 'darwin'* ]]; then
       brew install yq > /dev/null
       echo "Installed yq dependency"
   else
       sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 > /dev/null 2>&1
       sudo chmod a+x /usr/local/bin/yq
       echo "Installed yq dependency"
   fi
fi
}

getvalues(){
rm -rf values.yaml
echo "Getting values ..."
## Get the values.yaml
curl -o values.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/main/curl/4.1.2.1/values.yaml 2> /dev/null
}


isdmodevalues(){

if [[ $OSTYPE == 'darwin'* ]]; then
   sed -i.bu "s/oes.example.ops.com/$isduiurl/g" values.yaml
   sed -i.bu "s/vela.example.ops.com/$vela/g" values.yaml
else
   sed -i "s/oes.example.ops.com/$isduiurl/g" values.yaml
   sed -i "s/vela.example.ops.com/$vela/g" values.yaml
fi

yq e -i '.installArgoCD = false' values.yaml
yq e -i '.installArgoRollouts = false' values.yaml
yq e -i '.installArgoEvents = false' values.yaml
yq e -i '.installArgoWorkflows = false' values.yaml
yq e -i '.installationMode = "OEA-AP"' values.yaml
yq e -i '.installdemoapps = false' values.yaml
yq e -i '.autoconfigureagent = false' values.yaml
}

isdargomodevalues(){
if [[ $OSTYPE == 'darwin'* ]]; then
   sed -i.bu "s/oes.example.ops.com/$isduiurl/g" values.yaml
   sed -i.bu "s/cd.ryzon7-argo22.opsmx.org/$argocdurl/g" values.yaml
   #sed -i.bu "s/workflow.ryzon7-argo22.opsmx.org/$argowrkurl/g" values.yaml
   sed -i.bu "s/rollouts.ryzon7-argo22.opsmx.org/$argoroll/g" values.yaml
   sed -i.bu "s/vela.example.ops.com/$vela/g" values.yaml
else
   sed -i "s/oes.example.ops.com/$isduiurl/g" values.yaml
   sed -i "s/cd.ryzon7-argo22.opsmx.org/$argocdurl/g" values.yaml
   #sed -i "s/workflow.ryzon7-argo22.opsmx.org/$argowrkurl/g" values.yaml
   sed -i "s/rollouts.ryzon7-argo22.opsmx.org/$argoroll/g" values.yaml
   sed -i "s/vela.example.ops.com/$vela/g" values.yaml
fi

yq e -i '.cdagentname = "argocd"' values.yaml
yq e -i '.installArgoCD = true' values.yaml
yq e -i '.installArgoRollouts = true' values.yaml
yq e -i '.installArgoEvents = false' values.yaml
yq e -i '.installArgoWorkflows = false' values.yaml
yq e -i '.installationMode = "OEA-AP"' values.yaml
yq e -i '.installdemoapps = true' values.yaml
yq e -i '.autoconfigureagent = true' values.yaml
}

checkcrds(){
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
kubectl get CustomResourceDefinition applications.argoproj.io  > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "Existing CRD's applications.argoproj.io"
  yq e -i '.argo-cd.crds.install = false' values.yaml
else
  echo "CRD's applications.argoproj.io not present will be installed..."
  yq e -i '.argo-cd.crds.install = true' values.yaml
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

helminstallation(){
echo "-------------------------------------"
echo "             Installation     "
echo "-------------------------------------"
## Helm repo add
echo "Adding the helm repo...."
helm repo add isdargo https://opsmx.github.io/enterprise-argo/ > /dev/null 2>&1
echo "Updating the helm repo ..."
helm repo update > /dev/null 2>&1
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
###########################
#rm -rf enterprise-argo
#git clone https://github.com/OpsMx/enterprise-argo.git > /dev/null 2>&1
#cd enterprise-argo/charts/isdargo
#helm install $isdnamespace-isd . -f ../../../values.yaml --namespace $isdnamespace

####################
helm install isdargo$isdnamespace isdargo/isdargo -f values.yaml --version=$version --namespace $isdnamespace --timeout=15m
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
    rm -rf /tmp/inst.status
    kubectl get po -n $isdnamespace -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > /tmp/inst.status
    ## AUTOPILOT
    SAPOR=$(grep oes-sapor /tmp/inst.status | awk '{print $2}')
    PLATFORM=$(grep oes-platform /tmp/inst.status | awk '{print $2}')
    AUTOPILOT=$(grep oes-autopilot /tmp/inst.status | awk '{print $2}')
    ARGOSERVER=$(grep argocd-server /tmp/inst.status | awk '{print $2}')
    OESGATE=$(grep oes-gate /tmp/inst.status | awk '{print $2}')
    wait_period=$(($wait_period+10))
    READYBASIC=$([ "$OESGATE" == "true" ] &&[ "$ARGOSERVER" == "true" ] && [ "$SAPOR" == "true" ] && [ "$PLATFORM" == "true" ] && [ "$AUTOPILOT" == "true" ]; echo $(($? == 0)) )
    READY=$READYBASIC
    if [ $READY == 1 ];
    then
        echo "       ISD services are Up and Ready.."
        echo ""
        sleep 5
        echo "           ....Installation Completed Sucessfully...."
        echo ""
        echo "       Access the ISD          --> https://$isduiurl"
        echo ""
        echo "       Access the ArgoCD       --> https://$argocdurl"
        echo ""
        echo "       Access the Argorollouts --> https://$argoroll"
        echo ""
        echo "       Login with Openldap Credentials"
        echo ""
        echo "                           Username: admin"
        echo "                           Password: opsmxadmin123"
        echo "      ------------------------------------------------------"
        break
    else
        if [ $wait_period -gt 2000 ];
        then
            echo \"      Script is timed out as the ISD is not ready yet.......\"
            break
        else
            echo "       Waiting for ISD services to be ready"
            kubectl get po -n $isdnamespace | egrep 'ContainerStatusUnknown|CrashLoopBackOff|Evicted' | awk '{print $1}' | xargs kubectl delete po -n $isdnamespace > /dev/null 2>&1
            sleep 30
        fi
    fi
  done
else
  echo "ERROR: helm installation failed..."
  echo "ERROR: Some times it is due to timeout, Please check the pods and service...."
  exit 1
fi
}
isdcheck() {
if [ $? == 0 ];
then
  echo "-------------------------------------"
  echo "             Post Installation       "
  echo "-------------------------------------"
  echo "ISD services to be stabilize"
  wait_period=0
  while true
  do
    rm -rf /tmp/inst.status
    kubectl get po -n $isdnamespace -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > /tmp/inst.status
    ## AUTOPILOT
    SAPOR=$(grep oes-sapor /tmp/inst.status | awk '{print $2}')
    PLATFORM=$(grep oes-platform /tmp/inst.status | awk '{print $2}')
    AUTOPILOT=$(grep oes-autopilot /tmp/inst.status | awk '{print $2}')
    OESGATE=$(grep oes-gate /tmp/inst.status | awk '{print $2}')
    wait_period=$(($wait_period+10))
    READYBASIC=$([ "$OESGATE" == "true" ] && [ "$SAPOR" == "true" ] && [ "$PLATFORM" == "true" ] && [ "$AUTOPILOT" == "true" ]; echo $(($? == 0)) )
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
        echo "       Login with Openldap Credentials"
        echo ""
        echo "                           Username: admin"
        echo "                           Password: opsmxadmin123"
        echo "      ------------------------------------------------------"
        break
    else
        if [ $wait_period -gt 2000 ];
        then
            echo \"      Script is timed out as the ISD is not ready yet.......\"
            break
        else
            echo "       Waiting for ISD services to be ready"
            kubectl get po -n $isdnamespace | egrep 'ContainerStatusUnknown|CrashLoopBackOff|Evicted' | awk '{print $1}' | xargs kubectl delete po -n $isdnamespace > /dev/null 2>&1
            sleep 30
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
readmode
if [ "$isdmode" == "ISD" ];
then
   echo ""
   readnamespace
   readisdurl
   echo "---"
   checkdep
   getvalues
   isdmodevalues
   helminstallation
   isdcheck
elif [ "$isdmode" == "ISD-ARGO" ];
then
   echo ""
   readnamespace
   readisdurl
   readargourls
   checkdep
   getvalues
   checkcrds
   isdargomodevalues
   helminstallation
   isdargocheck
else
   echo "ERROR: Not specified None of the Modes - ISD or ISD-ARGO"
   exit 1
fi
