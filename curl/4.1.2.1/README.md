## Curl Quick Installtion

 - Single curl command to install the ISD services and argo componets with local services

   ### ISD-ARGO installtion 

        curl -o quickinstall.sh https://raw.githubusercontent.com/opsmx/enterprise-argo/main/curl/4.1.2/quickinstall.sh && chmod 777 quickinstall.sh && ./quickinstall.sh


## with DNS

- Single curl command to install the ISD services and argo componets with ingress,DNS

   ### 1. ISD-ARGO full installtion 

     ### Two modes
    
     - **ISD-ARGO** (Full installtion ISD and ARGO with agent)
     - **ISD**      (ISD Autopilot only)



           curl -o install.sh https://raw.githubusercontent.com/opsmx/enterprise-argo/main/curl/4.1.2/install.sh && chmod 777 install.sh && ./install.sh



   ### 2. AGENT installtion 


      curl -o agent.sh https://raw.githubusercontent.com/opsmx/enterprise-argo/main/curl/4.1.2/agent.sh && chmod 777 agent.sh && ./agent.sh



   ### 3. ARGO with AGENT installtion 


      curl -o argo-agent.sh https://raw.githubusercontent.com/opsmx/enterprise-argo/main/curl/4.1.2/argo-agent.sh && chmod 777 argo-agent.sh && ./argo-agent.sh

