# Maintence of CURL command as per release

- For each release new folder need to be created with release name
- Respected values.yaml file need to be placed in release folder before release(Do not point it to root folder values.yaml beacuse for each release fixed vaules need to be maintained)
- Update the values.yaml, dependent files RAW url in three scripts called **install.sh, agent.sh, argo-agent.sh and README.md** in release folder
