# enterprise-argo


For installing the Argo CD Please follow the below document

https://docs.google.com/document/d/1GWiyWp5e6v92x4quemc4W_-kWfx-hpzvxVnbEIBsTIk/edit#



Doc for Carina Service
https://docs.google.com/document/d/1Ovp9PYRQiGzcgCUxd7sQWurlJXd9lpNPhZvG5fgK4xk/edit

Agent Doc:
https://docs.google.com/document/d/1gAzG8hyQFqwAq5GOMlgIHK_5wE0lOweHsq5miyYrd6o/edit#heading=h.or0u4en44o5l





**Troubleshooting**

While installing if u face this error Unable to continue with install: CustomResourceDefinition "analysisruns.argoproj.io"

Please updated values.yaml with `argo-rollouts.installCRDs: false` and perform helm install.

While installing if u face this error Unable to continue with install: CustomResourceDefinition  "eventsources.argoproj.io"

Please updated values.yaml with `argo-events.crds.install: false` and perform helm install.


