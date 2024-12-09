
# Prototype Java Optimizing "native compiler" Service Broker for CF

Leverages v3 native image buildpack to co-deploy a natively compiled version existing JIT compiled & staged app, using a 'cf bind-service' call.

Uses 'cf-java-optimizer.sh' from https://github.com/tfynes-pivotal/cf-java-tools inside a service-broker construct.

deploy-broker.sh shows the service broker registration steps - broker itself is deployed as an app with a bound secret that provides it with cf-api credentials

## HowTo

1. Package JAR including graalvm tools maven dependency and "-Pnative" build argument (for maven)
2. cf-push application as normal
3. create instance of java-optimizer service from marketplace
4. bind service of java-optimizer to java app

## Behind the Scenes

1. Broker logs into cf
2. Broker downloads unstaged app-jar
3. Broker pushes jar under name <app-name>-native, with v3 native-image buildpack selected
4. Broker awaits for staging to complete, then shrinks footprint from 8GB down to 32MB by default
5. Broker binds <appname>-native instance to same ingress route as origin JIT compiled instance

pass in argument -c '{"memory":"128M"}' in bind service call to adjust behavior

Recommend: increase from 8GB to 12GB or 16GB in cf-java-optimizer.sh for native compiling of applications larger than 'hello-world'