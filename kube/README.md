# Deploying Gateway into Kubernetes

# Getting the gateway
In order to deploy a gateway into kubernetes, you will need to get a gateway from the ITRS docker registry.
In order to do this you will need to add a secret that will allow kubernetes to access the docker registry.
The kubernetes documentaton [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) takes you through these steps.
Please follow these instruction and create a secret called `docker.itrsgroup.com.cred`
 
If you do not have login credentials to the ITRS docker registry, you can request these from the [ITRS Registration](https://resources.itrsgroup.com/?register) page.

Choose the version of the gateway you wish to run and use that as the tag. So to run gateway GA5.4.0 you would use `docker.itrsgroup.com/gateway:5.4.0`.

# Delploying the gateway
In order to deploy the gateway, you need to use the yaml files.

In the example directory are a set if yaml files that will allow you to start and test a gateway in your cluster. To make life simple in the example there is no persistent volume and we run a "Demo Gateway" that should not be used in production.

Create the gateway config:
```
kubectl apply -f geneos-gateway-configmap.yaml
```

Create the gateway deployment:
```
kubectl apply -f geneos-gateway-deployment.yaml
```

Create the service
```
kubectl apply -f geneos-gateway-service.yaml
```

The gateway should now be running and accessable via the LoadBalancer.
Use AC2 to connect to the host that the Host and port the LoadBalancer creates for this service.

# Delploying multiple gateways

Each gateway needs to be run as a seperate service.
In the template directory you can see a set of tmpl files.
For each gateway these need to be edited as follows.
* Replace ${name} with a unique name that represents the gateway
* Replace ${licd} with the location of the Licence Demon (FQDN)
The command `create_gateway` will apply those changes to all 3 manifest templates creating a set of manifest yaml files. Add these 3 manifest files to the Kubernetes cluster using `kubectrl apply -f`.

Finally a persitent volume is needed to store the gateway setup files along with the runtime cache files (gateway.snoose, gateway.user_assignment, cache).
Both a PersistentVolume manifest and a PersistentVolumeClaim are needed. 
The name of the PersistentVolumeClaim should match the name returned when you ran `create_gateway

Each gateway when it starts will start with the default setup. That setup can then be updated via the GSE.


