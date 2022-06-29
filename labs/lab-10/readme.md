# lab-10 - ConfigMaps and secrets

## Estimated completion time - xx min

Kubernetes has two types of objects that can inject configuration data into a container when it starts up: Secrets and ConfigMaps. Secrets and ConfigMaps both can be exposed inside a container as mounted files (or volumes or environment variables). 

To explore Secrets and ConfigMaps, consider the following scenario:
* We use Database and we need to store connection string to the database. We are OK to save development connection string into `Database` section inside `appsettings.json`, but we don't want to store connection string  of database used from our AKS cluster, therefore we want to use Kubernetes secret to store Connection string
* We want to be able to change our logging verbosity without re-deploying or re-starting our application. We want to use build-in ASP.NET logging framework and configuration settings for that. For local development, we want to use `Logging` section of `appsettings.json` file.

## Application

To work with Secrets and ConfigMap, our test application was extended with 2 more controllers:

### SecretTestController 

This endpoint reads `Database:ConnectionString` from Configuration and writes logs it. 
* when you run you application locally and test `http://localhost:5000/secrettest` endpoint, you should see `[12:46:33 INF] [guinea-pig] - Database:ConnectionString: Connection string from local configuration file.` log line.

### ConfigMapTestController

This endpoint writes 4 different log levels:

* Info
* Warning
* Error
* Critical

With default log level configuration 

```json
"Logging": {
  "LogLevel": {
    "Default": "Information",
    "Microsoft": "Warning",
    "Microsoft.Hosting.Lifetime": "Information"
  }
}
```

we expect to see all 4 type of log levels, but after changing log level configuration to the following

```json
  "Logging": {
    "LogLevel": {
      "Default": "Error",
      "Microsoft": "Error",
      "Microsoft.Hosting.Lifetime": "Error"
    }
  }
```
we expect to see only logs of type `Warning` and `Critical`.

## Goals

In this lab you will learn how to:

* create Kubernetes secrets 
* mount contents of the Secret into the folder
* use Kubernetes secrets to override some properties in an ASP.NET Core app's configuration at runtime
* crate Kubernetes Config Map
* mount the contents of the config map into the folder
* use config map as mounted configuration file


## Task #1 - working with ConfigMap

Create `lab-10-logging-appsettings.yaml` manifest file with the following content 

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-appsettings
data:
  appsettings.json: |-
    {
      "Serilog": {
        "Using":  [ "Serilog.Sinks.Console" ],
        "MinimumLevel": {
          "Default": "Error",
          "Override": {
            "Microsoft": "Error",
            "Microsoft.Hosting.Lifetime": "Error"
          }
        },
        "WriteTo": [
          { "Name": "Console" }
        ],
        "Enrich": [ "FromLogContext", "WithMachineName", "WithThreadId" ],
        "Properties": {
          "Application": "guinea-pig"
        }
      }
    }
```

Deploy config map 

```bash
# Deploying config map from `lab-10-logging-appsettings.yaml` file
kubectl apply -f lab-10-logging-appsettings.yaml

# Get a list of config map instances
kubectl get configmap
NAME                  DATA   AGE
logging-appsettings   1      91m

# Get config map yaml. Note, I used alias cm instead of configmap
kubectl get cm logging-appsettings -o yaml

# Get configmap details
kubectl describe cm logging-appsettings
```

Create Deployment file `lab-10-task1-deployment.yaml` with the following definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-10-task1
  labels:
    app: lab-10-task1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lab-10-task1
  template:
    metadata:
      labels:
        app: lab-10-task1
    spec:
      containers:
      - name: api
        image: eratewsznjnxaunsoy42acr.azurecr.io/guinea-pig:v1
        imagePullPolicy: IfNotPresent
        resources: {}
        volumeMounts:
        - name: logging-config
          mountPath: /app/config          
      volumes:
      - name: logging-config
        configMap:
          name: logging-appsettings
```

Under the `volumes` section we added new item called `logging-config` of type `configMap` and we use ConfigMap `logging-appsettings` that we just deployed.
```yaml
      volumes:
      ...
      - name: logging-config
        configMap:
          name: logging-appsettings
```

Inside container template spec section we added the following configuration

```yaml
        volumeMounts:
        - name: logging-config
          mountPath: /app/config          
```

This configuration will create folder `app/config` inside pod filesystem and will map contents of ConfigMap into the files under this folder. In our case, `logging-appsettings` config map only contains one item called `appsettings.json`, so, we should expect one `appsettings.json` file created inside `app/config` folder. 

Now, let's deploy our Deployment

```bash
# Deploy lab-10-task1-deployment.yaml 
kubectl apply -f lab-10-task1-deployment.yaml

# Wait until deployment is successfully rolled out

# Get pod name
kubectl get po -l app=lab-10-task1
NAME                           READY   STATUS    RESTARTS   AGE
lab-10-task1-7bdfc94787-6nqnm   1/1     Running   0          50s

# Attach to the pod
kubectl exec -it lab-10-task1-7bdfc94787-6nqnm -- bash

# check the folder structure
root@lab-10-task1-7bdfc94787-6nqnm:/app#  ls

# Check the config folder
root@lab-10-task1-7bdfc94787-6nqnm:/app# ls config
appsettings.json

# Check content of config/appsettings.json file
root@lab-10-task1-7bdfc94787-6nqnm:/app# cat config/appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Error",
      "Microsoft": "Error",
      "Microsoft.Hosting.Lifetime": "Error"
    }
  }
}

# Exit
root@lab-10-task1-7bdfc94787-6nqnm:/app# exit
```

As you can see this file contains what's inside the Config Map `logging-appsettings->data.appsettings.json` element.

## Task #2 - create Kubernetes Secret and read it as Configuration parameter from the application

Create `appsettings.secrets.json` file with the following content. Imagine that it contains connection string to your database. You don't want to check it in, so most likely in real life you will generate this file based on either secret form Azure KeyVault, or read connection string from from Azure Cosmos DB or Azure SQL Server resource.

```json
{
    "Database": {
        "ConnectionString": "Connection string from kubernetes secret."
    }
}
```

Now create Kubernetes secret from this file using `kubectl create secret`

```bash
# Create new secret from the appsettings.secrets.json file
kubectl create secret generic secret-appsettings --from-file=./appsettings.secrets.json

# Get all secrets
kubectl get secret

# Get secret-appsettings secrets
kubectl get secret secret-appsettings

# Get detailed description of secret-appsettings secret
kubectl describe secret secret-appsettings

# Get secret-appsettings secrets yaml definition
kubectl get secret secret-appsettings -o yaml

# Get the contents of the Secret 
kubectl get secret secret-appsettings -o jsonpath='{.data}'
```

Now you can decode the data. If you are at Mac/linux, you most likely already have `base64` command installed. If you are on PowerShell, install `base64` with `choco`

```powershell
choco install base64
```
With `base64` installed, run the following command to decode secret data.

```powershell
# Get the contents of the Secret 
kubectl get secret secret-appsettings -o jsonpath='{.data}'
{"appsettings.secrets.json":"ew0KICAgICJEYXRhYmFzZSI6IHsNCiAgICAgICAgIkNvbm5lY3Rpb25TdHJpbmciOiAiQ29ubmVjdGlvbiBzdHJpbmcgZnJvbSBrdWJlcm5ldGVzIHNlY3JldC4iDQogICAgfQ0KfQ=="}

# Decode appsettings.secrets.json
echo ew0KICAgICJEYXRhYmFzZSI6IHsNCiAgICAgICAgIkNvbm5lY3Rpb25TdHJpbmciOiAiQ29ubmVjdGlvbiBzdHJpbmcgZnJvbSBrdWJlcm5ldGVzIHNlY3JldC4iDQogICAgfQ0KfQ== | base64 -d 
{
    "Database": {
        "ConnectionString": "Connection string from kubernetes secret."
    }
}
```

Create `lab-10-task2-deployment.yaml` file with the following Deployment definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-10-task2
  labels:
    app: lab-10-task2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lab-10-task2
  template:
    metadata:
      labels:
        app: lab-10-task2
    spec:
      containers:
      - name: api
        image: eratewsznjnxaunsoy42acr.azurecr.io/guinea-pig:v1
        imagePullPolicy: IfNotPresent
        resources: {}
        volumeMounts:
        - name: secrets
          mountPath: /app/secrets
          readOnly: true          
      volumes:
      - name: secrets
        secret:
          secretName: secret-appsettings
```

Note, under the `volumes` section we added new item called `secrets` of type `secret` and we use secret  `secret-appsettings` that we just deployed.

```yaml
      volumes:
      - name: secrets
        secret:
          secretName: secret-appsettings
```

Inside container template spec section we added the following configuration

```yaml
        volumeMounts:
        - name: secrets
          mountPath: /app/secrets
          readOnly: true          
```

This configuration will create folder `app/secrets` inside pod filesystem and will map contents of secret into the files under this folder. In our case, `secret-appsettings` secret only contains one data item called `appsettings.secrets.json`, so, we should expect one `appsettings.secrets.json` file created inside `app/secrets` folder. 

Now, let's deploy `lab-10-task2-deployment.yaml` Deployment

```bash
# Deploy lab-10-task2-deployment.yaml
kubectl apply -f lab-10-task2-deployment.yaml
deployment.apps/lab-10-task2 created

# Wait until deployment is successfully rolled out

# Get pod name
kubectl get po -l app=lab-10-task2
NAME                            READY   STATUS    RESTARTS   AGE
lab-10-task2-7986945b85-5mvsx   1/1     Running   0          13s

# Attach to the pod
kubectl exec -it lab-10-task2-7986945b85-5mvsx -- bash

# check the folder structure
root@lab-10-task2-7986945b85-5mvsx:/app# ls

# Check the secrets folder
root@lab-10-task2-7986945b85-5mvsx:/app# ls secrets
appsettings.secrets.json

# Check content of secrets/appsettings.secrets.json file
root@lab-10-task2-7986945b85-5mvsx:/app# cat secrets/appsettings.secrets.json
{
    "Database": {
        "ConnectionString": "Connection string from kubernetes secret."
    }
}

# Exit
root@lab-10-task2-7986945b85-5mvsx:/app# exit
```

Now, let's test the app. Split your terminal in two. At the right-hand window start the following command to stream logs from the pod

```bash
# Stream logs from lab-10-task1 pods
kubectl logs -l app=lab-10-task2 -f
```

The rest of the exercise do at the left-hand window.

```bash
# Get pod IP
kubectl get po -l app=lab-10-task2 -o wide
NAME                            READY   STATUS    RESTARTS   AGE    IP          NODE                             NOMINATED NODE   READINESS GATES
lab-10-task2-7986945b85-5mvsx   1/1     Running   0          2m2s   10.1.0.21   aks-system-11144696-vmss000000   <none>           <none>

# Start test shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh
# Test the secrettest endpoint several times
[ root@curl:/ ]$ curl http://10.1.0.21/secrettest
[ root@curl:/ ]$ curl http://10.1.0.21/secrettest
[ root@curl:/ ]$ curl http://10.1.0.21/secrettest
[secrettest] - OK
```

You should see the following logs at the log stream

```bash
[10:57:39 INF] [guinea-pig] - Database:ConnectionString: Connection string from kubernetes secret.
[10:57:40 INF] [guinea-pig] - Database:ConnectionString: Connection string from kubernetes secret.
[10:57:41 INF] [guinea-pig] - Database:ConnectionString: Connection string from kubernetes secret.
[10:57:41 INF] [guinea-pig] - Database:ConnectionString: Connection string from kubernetes secret.
```

As you can see, app reads connection string deployed as a secret. 


## Useful links

* [Managing ASP.NET Core App Settings on Kubernetes](https://anthonychu.ca/post/aspnet-core-appsettings-secrets-kubernetes/)
* [.NET Configuration in Kubernetes config maps with auto reload](https://medium.com/@fbeltrao/automatically-reload-configuration-changes-based-on-kubernetes-config-maps-in-a-net-d956f8c8399a)
* [.NET Configuration in Kubernetes config maps with auto reload - repo](https://github.com/fbeltrao/ConfigMapFileProvider)
* [Configuration in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?WT.mc_id=AZ-MVP-5003837&view=aspnetcore-5.0)
* [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
* [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
* [kubectl create secret](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-secret-em-)
* [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
* [Managing Secret using kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/)

## Next: configuring ingress with nginx

[Go to lab-11](../lab-11/readme.md)