# Token Rotation

The following steps will explain how to generate a new token & replace the token in Carina & Sapor secrets

## Pre-requisites: 

- User should have deployed 4.1.7 images

## Generate a new token & replace the token in Carina & Sapor secrets:

-  To create role & role binding, update the target namespace in the following job yaml and run the job <https://github.com/OpsMx/enterprise-argo/blob/v4.1.7/Token-Generation-And-Rotation/role-rb.yml>

 ```console
   kubectl apply -f role-rb.yml -n <namespace>
   ```
- To generate a new token for the first time, run the job <https://github.com/OpsMx/enterprise-argo/blob/v4.1.7/Token-Generation-And-Rotation/generate-token.yml>

   ```console
  kubectl apply -f generate-token.yml -n <namespace>
  ```
## To rotate token & replace the token in Carina & Sapor secrets:

-  To create role & role binding, update the target namespace in the following job yaml and run the job <https://github.com/OpsMx/enterprise-argo/blob/v4.1.7/Token-Generation-And-Rotation/role-rb.yml>

  ```console
   kubectl apply -f role-rb.yml -n <namespace>
   ```

- To rotate a token, run the following job yaml in the target namespace <https://github.com/OpsMx/enterprise-argo/blob/v4.1.7/Token-Generation-And-Rotation/rotate-token.yml>

   ```console
   kubectl apply -f rotate-token.yml -n <namespace>
   ``` 
**Note**: Wait until the token-rotation job status changes to “completed”
