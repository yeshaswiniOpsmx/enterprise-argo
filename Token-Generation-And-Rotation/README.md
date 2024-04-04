# Token Rotation

The following steps will explain how to generate a new token & replace the token in Carina & Sapor secrets

## Pre-requisites: 

- User should have previously deployed 4.1.7 and generated a token by following the steps mentioned in the following document: <https://docs.google.com/document/d/1ho9szu4qba5j6ItxBZhjMWOvIkUauEhw5U4mhLzKrwQ/edit>

## Steps for Token generation:

- Copy the file "sec-role.yml" to your local and replace the namespace with current namespace in the last row
-  Apply the below command 
-  ```console
   kubectl apply -f “sec-role.yml” -n <namespace>
   ```
**Note**: This is only one time activity and for the subsequent runs only job-test.yml should be applied.
- Now, Copy "job-test.yml" to your local and run the following command
- ```console
  kubectl apply -f “job-test.yml” -n <namespace>
  ```
Wait until the token-rotation job status changes to “completed”
