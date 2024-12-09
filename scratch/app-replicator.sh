#!/bin/bash

# Clone app (staged-droplet) into new space in single command
echo "INSIDE APP-REPLICATOR.SH"
# if [ "$#" -ne 14 ];
#   then 
#      echo "Usage app-replicator.sh <apiEndpointA> <cfUserA> <cfPassA> <orgA> <spaceA> <appNameA> <ingressDomainA> <apiEndpointB> <cfUserB> <cfPassB> <orgB> <spaceB> <appNameB> <ingressDomainB>"
#      exit 1
# fi


apiEndpointA=$1
cfUserA=$2
cfPassA=$3
orgA=$4
spaceA=$5
appNameA=$6
ingressDomainA=$7
apiEndpointB=$8
cfUserB=$9
cfPassB=${10}
orgB=${11}
spaceB=${12}
appNameB=${13}
ingressDomainB=${14}


export PATH=$PATH:/home/vcap/app
tmpdir=$(mktemp -d)
echo tmpdir = $tmpdir
pushd $tmpdir
cf login -a $apiEndpointA -u $cfUserA -p $cfPassA -o $orgA -s $spaceA
echo "SpaceA apps"
cf apps
cf download-droplet $appNameA -p ./$appNameA-droplet.tgz
ls -la
if [ -f "./$appNameA-droplet.tgz" ]; then
  echo droplet $appNameA-droplet.tgz download success
else
  echo droplet $appNameA-droplet.tgz download failure
fi
cf logout
cf login -a $apiEndpointB -u $cfUserB -p $cfPassB -o $orgB -s $spaceB
cf target
echo spaceB apps
cf apps
cf push $appNameB --droplet $appNameA-droplet.tgz  
if [ $? -ne 0 ]; then
 echo "CF PUSH ERROR: $?"
 exit 1
fi
rm -f ./$appNameA-droplet.tgz
popd
rm -fr $tmpdir