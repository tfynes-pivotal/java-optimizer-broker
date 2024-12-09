#!/bin/bash
echo bind-service called
echo args: 
for arg in "$@"; do
  if [[ $arg == --* ]]; then
      key=${arg%%=*}
    value=${arg#*=}
    key=${key#--}

    if [[ -z $key || -z $value ]]; then
      echo "Error: invalid arg format '$arg', use --key=value"
      exit 1
    fi

    declare "$key=$value"
  else
    echo "error: invalid argument format '$arg', use --key=value"
    exit 1
  fi
done

  export cf_api=$(echo $VCAP_SERVICES | jq -r '."user-provided"[] | select (.name=="cf-creds") | .credentials.api')
  export cf_username=$(echo $VCAP_SERVICES | jq -r '."user-provided"[] | select (.name=="cf-creds") | .credentials.username')
  export cf_password=$(echo $VCAP_SERVICES | jq -r '."user-provided"[] | select (.name=="cf-creds") | .credentials.password')


  export PATH=$PATH:/home/vcap/app
  export org_name=$(echo $context | sed "s/'/\"/g" | jq -r '.organization_name')
  export space_name=$(echo $context | sed "s/'/\"/g" | jq -r '.space_name')
  echo $org_name
  echo $space_name
  cf login -a $cf_api -u $cf_username -p $cf_password -o $org_name -s $space_name
  cf apps
  echo "PARAMS=$parameters"
  echo "jqparams"
  export app_name="$(cf curl /v3/apps/$app_guid | jq -r .name)"

  export jsonParameters=$(echo $parameters | sed "s/'/\"/g" )
  if echo $jsonParameters | jq -e "has(\"memory\")" > /dev/null 2>&1; then
    #echo key memory detected
    memory=$(echo $jsonParameters | jq ".memory")
    ./cf-java-optimizer.sh $app_name $memory &
  else
    #echo key memory not found
    ./cf-java-optimizer.sh $app_name &
  fi
  
  


    # echo "BIND-SERVICE ARGS:"
    # for var in $(compgen -A variable); do
    #   if [[ $var != _* ]]; then
    #     echo "ARGUMENT: $var=${!var}"
    #   fi
    # done

