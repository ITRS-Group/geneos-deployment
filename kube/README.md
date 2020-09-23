# Deploying Gateway into Kubernetes

# Getting the gateway
In order to deploy a gateway into kubernetes, you will need to get a gateway image from the ITRS docker registry.
In order to do this you will need to add a secret that will allow kubernetes to access the docker registry.
The kubernetes documentaton [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) takes you through these steps.
Please follow these instruction and create a secret called `docker.itrsgroup.com.cred`
 
If you do not have login credentials to the ITRS docker registry, you can request these from the [ITRS Registration](https://resources.itrsgroup.com/?register) page.

Choose the version of the gateway you wish to run and use that as the tag. So to run gateway GA5.4.0 you would use `docker.itrsgroup.com/gateway:5.4.0`.

# Delploying the gateway
In order to deploy the gateway, you need to use a set of yaml manifest files.

In the example directory are a set if yaml files that will allow you to start and test a gateway in your cluster.
To make life simple in the example we run a "Demo Gateway" that should not be used in production, 
but does not require access to a license deamon.


### Create the gateway persistence volume claim. 
Before this manifest is applied you may need to edit the volume claim to ensure that a volume can be created. 
Either a `PersistentVolume` manifest must be created to than references the persistent volume claim, 
or the `storageClassName` must be added to the `PersistentVolumeClaim` and it must be match a storage class 
that supports dynamic allocation of persistent volumes in your cluster.
```
kubectl apply -f geneos-gateway-pvc.yaml
```

### Create the gateway config
This will mount a read only `ConfigMap` folder onto the kubernetes container. That `ConfigMap` should contain the gateway commandline parameters. 
```
kubectl apply -f geneos-gateway-configmap.yaml
```

### Create the gateway deployment
This creates a deployment that will create a Pod that runs the gateway uing the `PersistentVolume` accessed through the `PersistentVolumeClaim` to store the setup and runtime data. It will start the gateway using the command line read from its `ConfigMap`.
```
kubectl apply -f geneos-gateway-deployment.yaml
```

### Create the service
This will create a service that routes TCP traffic to the gateway. It can be used by both Active Console and external netprobes to access the gateway process.

```
kubectl apply -f geneos-gateway-service.yaml
```

The gateway should now be running and accessible via the LoadBalancer.
Use AC2 to connect to the host that the Host and port the LoadBalancer creates for this service.

# Delploying multiple gateways

Each gateway needs to be run as a separate service.
Take the example service and edit as needed. 
The names of all 4 manifests (`ConfigMap`, `Deployment`, `PersistentVolumeClaim` and `Service`) will need to be updated.




