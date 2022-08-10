# enterprise-argo


For installing the Argo CD below are the mandatory paramerts to be updated in values.yaml

1. Host value for ArgoCD host value in below path ` `global.argocd.host`

2. Host value for ArgoWorkflows `global.argworkflows.host`

3. Update the ArgoCD host value in below path `argo-cd.server.config.url`




Troubleshooting

While installing if u face this error Unable to continue with install: CustomResourceDefinition "analysisruns.argoproj.io"

Please updated values.yaml with `argo-rollouts.installCRDs: false` and perform helm install.

While installing if u face this error Unable to continue with install: CustomResourceDefinition  "eventsources.argoproj.io"

Please updated values.yaml with `argo-events.crds.install: false` and perform helm install.
