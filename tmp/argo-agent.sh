#!/bin/bash

#set -x

isdlogo(){
## Chart Version 
version=4.1.3
echo ""
echo ""
echo "     _      ____     ____    ___               _       ____   _____   _   _   _____  "
echo "    / \    |  _ \   / ___|  / _ \             / \     / ___| | ____| | \ | | |_   _| "
echo "   / _ \   | |_) | | |  _  | | | |  _____    / _ \   | |  _  |  _|   |  \| |   | |   "
echo "  / ___ \  |  _ <  | |_| | | |_| | |_____|  / ___ \  | |_| | | |___  | |\  |   | |   "
echo " /_/   \_\ |_| \_\  \____|  \___/          /_/   \_\  \____| |_____| |_| \_|   |_|   "
echo "                                                                                     "
echo "                                                                                     "
echo "------------------------------------------------------------"
echo " System Requirements "
echo "------------------------------------------------------------"
echo "   Configuration with at least 4 cores and 16 GB memory"
echo "   Kubernetes cluster 1.22 or later                    "
echo "   Helm 3 is setup on the client system   Installation - https://helm.sh/docs/intro/install/"
echo "   Nginx ingress controlled installed     Installation - https://kubernetes.github.io/ingress-nginx/deploy/"
echo "   Cert-manager installed                 Installation - https://cert-manager.io/docs/installation/kubernetes/"
echo "------------------------------------------------------------"
echo " Prerequisite:"
echo "------------------------------------------------------------"
echo "             1. ISD installed"
echo "             2. Controller mapped to the DNS"
echo "                    CHECK: nslookup <controller DNS>"
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

readnamespace(){
## Read Namespace
echo -n "Specify Namespace: "
while read argonamespace; do
  test "$argonamespace" != "" && break
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
  echo -n "Your ISD-UI URL: "
done
echo -n "Specify ISD Username: "
while read isdusername; do
  test "$isdusername" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ISD Username : "
done

echo -n "Specify ISD Password: "
while read isdpassword; do
  test "$isdpassword" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ISD Password : "
done
echo -n "Specify Controller DNS: "
while read controllerdns; do
  test "$controllerdns" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Controller DNS : "
done
}
readargourls(){
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

echo -n "Specify Agent name: "
while read agentname; do
  test "$agentname" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Agent Name in ISD : "
done
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

## argocli installed
argocd > /dev/null 2>&1
if [ $? == 0 ];
then
  echo "ArgoCLI present in server.."
else
  #Installing Argo CLI
  sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 > /dev/null
  sudo chmod +x /usr/local/bin/argocd
  echo "Installed ArgoCLI dependency"
fi
}

getvalues(){
rm -rf values.yaml
## Get the vaules.yaml
curl -o values.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/4.1.3/curl/4.1.3/values.yaml 2> /dev/null
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

argomodevalues(){
if [[ $OSTYPE == 'darwin'* ]]; then
  sed -i.bu "s/cd.ryzon7-argo22.opsmx.org/$argocdurl/g" values.yaml
  #sed -i.bu "s/workflow.ryzon7-argo22.opsmx.org/$argowrkurl/g" values.yaml
  sed -i.bu "s/rollouts.ryzon7-argo22.opsmx.org/$argoroll/g" values.yaml
else
  sed -i "s/cd.ryzon7-argo22.opsmx.org/$argocdurl/g" values.yaml
  #sed -i "s/workflow.ryzon7-argo22.opsmx.org/$argowrkurl/g" values.yaml
  sed -i "s/rollouts.ryzon7-argo22.opsmx.org/$argoroll/g" values.yaml
fi
yq e -i '.cdagentname = "'argocd-$agentname'"' values.yaml
yq e -i '.installArgoCD = true' values.yaml
yq e -i '.installArgoRollouts = true' values.yaml
yq e -i '.installArgoEvents = false' values.yaml
yq e -i '.installArgoWorkflows = false' values.yaml
yq e -i '.installationMode = "None"' values.yaml
yq e -i '.installdemoapps = true' values.yaml
yq e -i '.autoconfigureagent = false' values.yaml
yq e -i '.installRedis = false' values.yaml
yq e -i '.minio.enabled = false' values.yaml

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
kubectl create namespace $argonamespace
if [ $? == 0 ];
then
        echo ""
else
       echo "Namespace already exists.."
       echo -n "Specify Namespace: "
       while read argonamespace; do
          test "$argonamespace" != "" && kubectl create namespace $argonamespace && break
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
#helm install $argonamespace-isd . -f ../../../values.yaml --namespace $argonamespace
helm install isdargo-$argonamespace isdargo/isdargo -f values.yaml --version=$version --namespace $argonamespace --timeout=15m

####################
}
argocheck() {
if [ $? == 0 ];
then
  echo "-------------------------------------"
  echo "             Post Installation       "
  echo "-------------------------------------"
  echo "ARGO services to be stabilize"
  wait_period=0
  while true
  do
    #live status of pods
    rm /tmp/inst.status
    kubectl get po -n $argonamespace -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > /tmp/inst.status
    #Check argocd url status
    status="$(curl -Is https://$argocdurl | head -1)"
    validate=$(echo $status | awk '{print $2}')
    
    #Check isd url status
    isdstatus="$(curl -Is https://$isduiurl | head -1)"
    isdvalidate=$(echo $isdstatus | awk '{print $2}')
    
    ## ARGO service
    ARGOREPOSERVER=$(grep argocd-repo-server /tmp/inst.status | awk '{print $2}')
    ARGOSERVER=$(grep argocd-server /tmp/inst.status | awk '{print $2}')
    wait_period=$(($wait_period+10))
    READYBASIC=$([ "$validate" == "200" ] && [ "$isdvalidate" == "302" ] && [ "$ARGOSERVER" == "true" ] && [ "$ARGOREPOSERVER" == "true" ]; echo $(($? == 0)) )
    READY=$READYBASIC
    if [ $READY == 1 ];
    then
      # Get service name
      argosvcname=$(kubectl get svc -n $argonamespace -l app.kubernetes.io/name=argocd-server | awk '{print $1}' | tail -1)
      echo "       ARGO services are Up and Ready.."
      echo ""
      while true
      do
      ##argocli login
      argocdpassword=$(kubectl -n $argonamespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
      argocd login  $argocdurl --username=admin --password=$argocdpassword --grpc-web
      token=$(argocd account generate-token)
      wait=0
      if [ -z $token ]
      then
        wait=$(($wait+10))
        if [ $wait -gt 2000 ];
        then
          echo \"Script is timed out Admin Secret not found .......\"
          break
        else
          echo \"Waiting to get the admin token\"
          sleep 1m
        fi
      else
         encodedtoken=$(echo -n $token | base64 -w0)
         isdenocdedcred=$(echo -n $isdusername:$isdpassword | base64 -w0)
         ##Configure the Agent to the ISD
         #Create Agent in the ISD-UI via API
         sleep 20
         curl --location --request POST 'https://'$isduiurl'/gate/oes/accountsConfig/v3/agents?cdType=Argo' --header 'Content-Type: application/json' --header 'Authorization: Basic '$isdenocdedcred'' --data-raw '{"agentName":"'$agentname'","description":"Agent is running '$argonamespace' namespace"}'
         sleep 20
         ##Download the manifest
	 rm -rf /tmp/$agentname-manifest.yaml
         curl --location --request GET 'https://'$isduiurl'/gate/oes/accountsConfig/agents/'$agentname'/manifest' --header 'Authorization: Basic '$isdenocdedcred'' > /tmp/$agentname-manifest.yaml
         cd /tmp/
	 sudo rm -rf /tmp/kubectl-slice_1.2.3_linux_x86_64.tar.gz
         ## Download and install the kubectl-slice to split to manifest file that is download
         wget -O /tmp/kubectl-slice_1.2.3_linux_x86_64.tar.gz https://github.com/patrickdappollonio/kubectl-slice/releases/download/v1.2.3/kubectl-slice_1.2.3_linux_x86_64.tar.gz > /dev/null 2>&1
         tar -xvf /tmp/kubectl-slice_1.2.3_linux_x86_64.tar.gz
         sudo cp /tmp/kubectl-slice /usr/local/bin/

         #Need to remove at the end
         sudo rm -rf /tmp/yamls/

         ## slice command to extract file
         kubectl-slice --input-file=/tmp/$agentname-manifest.yaml --output-dir=/tmp/yamls/.

         # Download Agent CM file
         curl -o /tmp/yamls/opsmx-services-agent.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/4.1.3/curl/4.1.3/opsmx-services-agent.yaml > /dev/null 2>&1

         if [[ $OSTYPE == 'darwin'* ]]; then
           ## Replace the namespace in the manifest
           sed -i.bu 's/default/'$argonamespace'/g' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.subjects[0].namespace = "'$argonamespace'"' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.data[.controllerHostname] = "controllerHostname: '$controllerdns':9001"' /tmp/yamls/configmap-opsmx-agent-$agentname.yaml
           #Replacing the values
           sed -i.bu 's/AGENTNAME/'$agentname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/ARGOCDSVCNAME/'$argosvcname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/ARGOCDURL/'$argocdurl'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/token: .*xxx/token: '$encodedtoken'/g' /tmp/yamls/opsmx-services-agent.yaml

	 else
           ## Replace the namespace in the manifest
           sed -i 's/default/'$argonamespace'/g' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.subjects[0].namespace = "'$argonamespace'"' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.data[.controllerHostname] = "controllerHostname: '$controllerdns':9001"' /tmp/yamls/configmap-opsmx-agent-$agentname.yaml
	   #Replacing the values
           sed -i 's/AGENTNAME/'$agentname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/ARGOCDSVCNAME/'$argosvcname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/ARGOCDURL/'$argocdurl'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/token: .*xxx/token: '$encodedtoken'/g' /tmp/yamls/opsmx-services-agent.yaml
	 fi
         echo ""
         echo "-------------------------------------------------"
         echo "   Applying the agent file in argocd namespcace"
         ## Apply the yamls
         kubectl apply -f /tmp/yamls/ -n $argonamespace
         echo ""
         echo "-------------------------------------------------------"
         echo "           ....Installation Completed Sucessfully...."
         echo ""
         echo "Access the URL's:"
         echo "        ISD         : https://$isduiurl"
         echo "        ArgoCD      : https://$argocdurl"
         echo "        ArgoRollouts: https://$argoroll"
         echo ""
         echo "   Credentials : "
         echo "               Username: $isdusername"
         echo "               Password: $isdpassword"
         echo ""
         echo "-------------------------------------------------------"
         break
      fi
    done
    break
  else
    if [ $wait_period -gt 2000 ];
    then
      echo \"      Script is timed out as the ISD is not ready yet.......\"
      break
    else
      echo "       Waiting for ARGO services to be ready"
      kubectl get po -n $argonamespace | egrep 'ContainerStatusUnknown|CrashLoopBackOff|Evicted' | awk '{print $1}' | xargs kubectl delete po -n $argonamespace > /dev/null 2>&1
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
readnamespace
readisdurl
readargourls
checkdep
getvalues
checkcrds
argomodevalues
helminstallation
argocheck
