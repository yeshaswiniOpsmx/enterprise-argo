# Curl Installtion

- Single curl command to install the ISD services and argo componets

## 1. ISD-ARGO full installtion 

  ### Two modes
    
  - **ISD-ARGO** (Full installtion ISD and ARGO with agent)
  - **ISD**      (ISD Autopilot only)



        curl -o install.sh https://raw.githubusercontent.com/maheshopsmx/enterprise-argo/main/curl/4.1.1/install.sh && chmod 777 install.sh && ./install.sh



## 2. AGENT installtion 


      curl -o agent.sh https://raw.githubusercontent.com/maheshopsmx/enterprise-argo/main/curl/4.1.1/agent.sh && chmod 777 agent.sh && ./agent.sh



## 3. ARGO with AGENT installtion 


      curl -o argo-agent.sh https://raw.githubusercontent.com/maheshopsmx/enterprise-argo/main/curl/4.1.1/argo-agent.sh && chmod 777 argo-agent.sh && ./argo-agent.sh

