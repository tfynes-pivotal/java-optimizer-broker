#!/bin/bash

# Clone app (staged-droplet) into new space in single command
echo "INSIDE APP-LOCAL-COPY.SH"
if [ "$#" -ne 8 ];
  then 
     echo "Usage app-local-copy.sh <apiEndpoint> <cfUser> <cfPass> <org> <space> <app name> <app2 name> <ingress domain>"
     exit 1
fi


apiEndpoint=$1
cfUser=$2
cfPass=$3
org=$4
space=$5
appName=$6
app2Name=$7
ingressDomain=$8

export PATH=$PATH:/home/vcap/app
#tmpdir=$(mktemp -d)
#echo tmpdir = $tmpdir
#pushd $tmpdir
cf login -a $apiEndpoint -u $cfUser -p $cfPass -o $org -s $space 
#echo curl -s -L -H "Authorization: $(cf oauth-token)" $apiEndpoint/v3/droplets/$(cf app $appName --guid)/download --output ./$appName-droplet.tgz
#curl -s -L -H "Authorization: $(cf oauth-token)" $apiEndpoint/v3/droplets/$(cf app $appName --guid)/download --output ./$appName-droplet.tgz
#export appGuid=$(cf app tmf-tdemo-native --guid)
#export dropletGuid=$(cf curl /v3/apps/$appGuid/droplets | jq -r .resources[0].guid)
#export token=$(cf oauth-token) 
#curl -s -L -H "Authorization: $token" $apiEndpoint/v3/droplets/$dropletGuid/download --output /tmp/$appName-droplet.tgz


echo cf download-droplet $appName -p ./$appName-droplet.tgz
cf download-droplet $appName -p ./$appName-droplet.tgz
#pwd
ls -la 
cf apps
if [ -f "./$appName-droplet.tgz" ]; then
  echo droplet $appName-droplet.tgz exists
else
  echo droplet $appName-droplet.tgz not found
fi
echo cf push $app2Name --droplet $appName-droplet.tgz  
#export CF_TRACE=true
cf push $app2Name --droplet "$appName-droplet.tgz"  
if [ $? -ne 0 ]; then
 echo "CF PUSH ERROR: $?"
 exit 1
fi
#echo cf map-route $app2Name $ingressDomain --hostname $app2Name
#cf map-route $app2Name $ingressDomain --hostname $app2Name
#cf start $app2Name
rm -f ./$appName-droplet.tgz
#popd
rm -fr $tmpdir