
cf cups cf-creds -p ./cf-creds.json
cf push 
cf create-service-broker java-optimizer-broker admin https://java-optimizer-broker.<mydomain>
cf enable-service-access java-optimizer