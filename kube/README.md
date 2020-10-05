# Deploying Gateway into Kubernetes

# Getting the Gateway
In order to deploy a gateway into Kubernetes, you will need to get a gateway image from the ITRS docker registry.
In order to do this you will need to add a secret that will allow Kubernetes to access the docker registry.
The Kubernetes documentation takes you through these steps in the [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) page.
Please follow these instruction and create a secret called `docker.itrsgroup.com.cred`
 
This requires login credentials to the ITRS docker registry. If you do not have credentials, you can request these from the [ITRS Registration](https://resources.itrsgroup.com/?register) page.

Image names use the format `<product>:<version>`. So to run gateway GA5.4.0 you would use `docker.itrsgroup.com/gateway:5.4.0`.

# Deploying the Gateway
In order to deploy the Gateway, you need a set of yaml manifest files.

In the example directory there are a set if yaml files that will allow you to start and test a Gateway in your cluster. In the example we run a "Demo Gateway" that should not be used in production, but also does not require access to a license daemon.


### Create the Gateway persistence volume claim. 
Before this manifest is applied you may need to edit the volume claim to ensure that a volume can be created. 
Either a `PersistentVolume` manifest must be created that then references the persistent volume claim, 
or the `storageClassName` must be added to the `PersistentVolumeClaim` that must match a storage class 
that supports dynamic allocation of persistent volumes in your cluster.

To create the persistence volume claim:
```
kubectl apply -f geneos-gateway-pvc.yaml
```

### Create the Gateway config
Create a `ConfigMap` that contains the Gateway commandline parameters.

To mount your read only `ConfigMap` folder into the Kubernetes container:
```
kubectl apply -f geneos-gateway-configmap.yaml
```

### Create the Gateway deployment
Configure a deployment that will create a Pod that runs the Gateway using the `PersistentVolume` accessed through the `PersistentVolumeClaim` to store the setup and runtime data. This will start the Gateway using the command line read from its `ConfigMap`.
```
kubectl apply -f geneos-gateway-deployment.yaml
```

### Create the service
Create a service that routes TCP traffic to the Gateway. This can be used by both Active Console and external Netprobes to access the Gateway process.

```
kubectl apply -f geneos-gateway-service.yaml
```

The Gateway should now be running and accessible via the LoadBalancer.
Use Active Console to connect to the host and port the LoadBalancer creates for this service.

# Deploying multiple Gateways

- Each Gateway needs to be run as a separate service.
- Take the example service and edit as needed. 
The names of all 4 manifests (`ConfigMap`, `Deployment`, `PersistentVolumeClaim` and `Service`) will need to be updated.




