#! /bin/bash

echo "                                           "
echo "      _       ____   _____   _   _   _____ "
echo "     / \     / ___| | ____| | \ | | |_   _|"
echo "    / _ \   | |  _  |  _|   |  \| |   | |  "
echo "   / ___ \  | |_| | | |___  | |\  |   | |  "
echo "  /_/   \_\  \____| |_____| |_| \_|   |_|  "
echo "                                           "
echo "-------------------------------------------"
echo " Prerequisite"
echo "-------------------------------------------"
echo "         1. ISD installed "
echo "         2. Argo installed"
echo "         3. Controller mapped to the DNS"
echo "                    CHECK: nslookup <controller DNS>"
echo "---"
echo "Please specify required data to configure Argo Agent with ISD"
echo ""
echo -n "Specify Agent name: "
while read agentname; do
  test "$agentname" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Agent Name in ISD : "
done

echo -n "Specify ISD URL: "
while read isdurl; do
  test "$isdurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ISD URL : "
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


echo -n "Specify ArgoCD URL: "
while read argocdurl; do
  test "$argocdurl" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoCD URL : "
done

echo -n "Specify ArgoCD Username: "
while read argocdusername; do
  test "$argocdusername" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoCD Username : "
done

#echo -n "Specify ArgoCD Password: "
#while read argocdpassword; do
#  test "$argocdpassword" != "" && break
#  echo "              INFO: ANSWER CANNOT BE BLANK!"
#  echo ""
#  echo -n "Your ArgoCD Password : "
#done

echo -n "Specify ArgoCD Installed Namespace : "
while read argocdnamespace; do
  test "$argocdnamespace" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your ArgoCD Installed Namespace : "
done


echo -n "Specify Controller DNS: "
while read controllerdns; do
  test "$controllerdns" != "" && break
  echo "              INFO: ANSWER CANNOT BE BLANK!"
  echo ""
  echo -n "Your Controller DNS : "
done
echo ""

echo "Checking for dependency......"
## check kubectl
#kubectl version > /dev/null 2>&1
#if [ $? == 0 ];
#then
##  echo "Kubectl present in server.."
#else
#  echo "ERROR: kubectl not installed ..."
#  exit 1
#fi

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

echo "------------------"
echo \"Waiting for all Argo Server  to come-up\"
wait_period=0
while true
do

  # Get service name
  argosvcname=$(kubectl get svc -n $argocdnamespace -l app.kubernetes.io/name=argocd-server | awk '{print $1}' | tail -1)

  #Check argocd url status
  status="$(curl -Is https://$argocdurl | head -1)"
  validate=$(echo $status | awk '{print $2}')

  #Check isd url status
  isdstatus="$(curl -Is https://$isdurl | head -1)"
  isdvalidate=$(echo $isdstatus | awk '{print $2}')
  
  #live status of pods
  rm -rf /tmp/live.status
  kubectl get po -n $argocdnamespace -o jsonpath='{range .items[*]}{..metadata.name}{"\t"}{..containerStatuses..ready}{"\n"}{end}' > /tmp/live.status
  ARGOCDSERVER=$(grep argocd-server /tmp/live.status |grep -v deck | awk '{print $2}')

  wait_period=$(($wait_period+10))
  if  [ "$ARGOCDSERVER" == "true" ] && [ "$validate" == "200" ] && [ "$isdvalidate" == "302" ] ;
  then
      echo \"ArgocdServer is  Up and Ready..\"
      while true
      do
      ##argocli login
      argocdpassword=$(kubectl -n $argocdnamespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
      argocd login  $argocdurl --username=$argocdusername --password=$argocdpassword --grpc-web
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
         curl --location --request POST 'https://'$isdurl'/gate/oes/accountsConfig/v3/agents?cdType=Argo' --header 'Content-Type: application/json' --header 'Authorization: Basic '$isdenocdedcred'' --data-raw '{"agentName":"'$agentname'","description":"Agent is running '$argocdnamespace' namespace"}'

         sleep 20
         ##Download the manifest
	 rm -rf /tmp/$agentname-manifest.yaml
         curl --location --request GET 'https://'$isdurl'/gate/oes/accountsConfig/agents/'$agentname'/manifest' --header 'Authorization: Basic '$isdenocdedcred'' > /tmp/$agentname-manifest.yaml

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
         mkdir /tmp/yamls/agent
         # Download Agent CM file
         curl -o /tmp/yamls/opsmx-services-agent.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/main/curl/4.1.1/opsmx-services-agent.yaml > /dev/null 2>&1
         curl -o /tmp/yamls/agent/opsmx-profile.yaml https://raw.githubusercontent.com/OpsMx/enterprise-argo/main/curl/4.1.1/opsmx-profile.yaml

         if [[ $OSTYPE == 'darwin'* ]]; then
           ## Replace the namespace in the manifest
           sed -i.bu 's/default/'$argocdnamespace'/g' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.subjects[0].namespace = "'$argocdnamespace'"' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.data[.controllerHostname] = "controllerHostname: '$controllerdns':9001"' /tmp/yamls/configmap-opsmx-agent-$agentname.yaml

           #Replacing the values
           sed -i.bu 's/AGENTNAME/'$agentname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/AGENTNAME/'$agentname'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i.bu 's/ISDURL/'$isdurl'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i.bu 's/ISDUSERNAME/'$isdusername'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i.bu 's/ARGOCDSVCNAME/'$argosvcname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/ARGOCDURL/'$argocdurl'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i.bu 's/token: .*xxx/token: '$encodedtoken'/g' /tmp/yamls/opsmx-services-agent.yaml
         else
           ## Replace the namespace in the manifest
           sed -i 's/default/'$argocdnamespace'/g' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.subjects[0].namespace = "'$argocdnamespace'"' /tmp/yamls/clusterrolebinding-opsmx-agent-$agentname.yaml
           #yq e -i '.data[.controllerHostname] = "controllerHostname: '$controllerdns':9001"' /tmp/yamls/configmap-opsmx-agent-$agentname.yaml

	   #Replacing the values
           sed -i 's/AGENTNAME/'$agentname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/AGENTNAME/'$agentname'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i 's/ISDURL/'$isdurl'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i 's/ISDUSERNAME/'$isdusername'/g' /tmp/yamls/agent/opsmx-profile.yaml
           sed -i 's/ARGOCDSVCNAME/'$argosvcname'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/ARGOCDURL/'$argocdurl'/g' /tmp/yamls/opsmx-services-agent.yaml
           sed -i 's/token: .*xxx/token: '$encodedtoken'/g' /tmp/yamls/opsmx-services-agent.yaml
         fi

         echo ""
         echo "-------------------------------------------------"
         echo "   Applying the agent file in argocd namespcace"
         ## Apply the yamls
         kubectl replace --force -f /tmp/yamls/agent/opsmx-profile.yaml -n $argocdnamespace
         kubectl apply -f /tmp/yamls/ -n $argocdnamespace
         echo ""
         echo "-------------------------------------------------------"
         echo "                Agent configured succesfully"
         echo ""
         echo "Access the ISD : https://$isdurl"
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
       echo \"Script is timed out as the Argocd Server is not ready yet.......\"
       break
      else
       echo \"Waiting for  Argocd Server to be ready\"
       sleep 30
      fi
  fi
done
