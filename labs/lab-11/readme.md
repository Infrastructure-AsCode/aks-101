# lab-11 - configuring ingress with nginx

## Estimated completion time - xx min

An ingress controller is a piece of software that provides reverse proxy, configurable traffic routing, and TLS termination for Kubernetes services. Kubernetes ingress resources are used to configure the ingress rules and routes for individual Kubernetes services. Using an ingress controller and ingress rules, a single IP address can be used to route traffic to multiple services in a Kubernetes cluster.

![https://www.nginx.com/blog/wait-which-nginx-ingress-controller-kubernetes-am-i-using/](images/NGINX-Ingress-Controller-4-services.png)

## Goals

This lab shows you how to deploy the NGINX ingress controller in an AKS cluster. The ingress controller is configured on an internal, private virtual network and IP address. No external access is allowed. Two applications are then run in the AKS cluster, each of which is accessible over the single IP address.

You will learn how to:

* Implement `ingress` routes to expose kubernetes services 

...

No ingress rules have been created yet, so the NGINX ingress controller's default 404 page is displayed if you browse to the internal IP address. Ingress rules are configured in the following tasks.

```bash
# Start curl pod with interactive shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Try to access our 
[ root@curl:/ ]$ curl http://10.11.0.146
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
[ root@curl:/ ]$ exit
```

To see the ingress controller in action, let's deploy two applications in our AKS cluster. 

## Task #2 - deploy guinea-pig-lab11-task1 application 

Create `guinea-pig-lab11-task1-deployment.yaml` file with the following k8s resources:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guinea-pig-lab11-task1
  labels:
    app: guinea-pig-lab11-task1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: guinea-pig-lab11-task1
  template:
    metadata:
      labels:
        app: guinea-pig-lab11-task1
    spec:
      containers:
      - name: api
        image: eratewsznjnxaunsoy42acr.azurecr.io/guinea-pig:v1
        imagePullPolicy: IfNotPresent
        resources: {}
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3    
        readinessProbe:
          httpGet:
            path: /readiness
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: guinea-pig-lab11-task1-service
  labels:
    app: guinea-pig-lab11-task1
spec:
  ports:
  - port: 8081
    protocol: TCP
    targetPort: 80
  selector:
    app: guinea-pig-lab11-task1
  type: ClusterIP
```

```bash
# Deploy guinea-pig-lab11-task1 application
kubectl apply -f guinea-pig-lab11-task1-deployment.yaml
deployment.apps/guinea-pig-lab11-task1 created
service/guinea-pig-lab11-task1-service created
```
As you can see, here we deployed two replicas of guinea-pig-lab11-task1 and service exposed at port `8081`. Now, let's test it:

```bash
# Start test pod with interactive shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test api
[ root@curl:/ ]$ curl http://guinea-pig-lab11-task1-service:8081/api
[api] - OK.
[ root@curl:/ ]$ exit
```

## Task #3 - deploy api-b applications 

Create `api-b-deployment.yaml` file with the following k8s resources:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-b-appsettings
data:
  appsettings.json: |-
    {
      "ApiAServiceUrl": "http://guinea-pig-lab11-task1-service:8081/api"      
    }
---    
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-b
  labels:
    app: api-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-b
  template:
    metadata:
      labels:
        app: api-b
        aadpodidbinding: api-b
    spec:
      containers:
      - name: api
        image: iacws2<YOUR-NAME>acr.azurecr.io/apib:v1
        imagePullPolicy: IfNotPresent
        resources: {}
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3    
        readinessProbe:
          httpGet:
            path: /readiness
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
        volumeMounts:
        - name: appsettings
          mountPath: /app/config          
      volumes:
      - name: appsettings
        configMap:
          name: api-b-appsettings
---
apiVersion: v1
kind: Service
metadata:
  name: api-b-service
  labels:
    app: api-b
spec:
  ports:
  - port: 8081
    protocol: TCP
    targetPort: 80
  selector:
    app: api-b
  type: ClusterIP
```

```bash
# Deploy guinea-pig-lab11-task1 application
kubectl apply -f api-b-deployment.yaml
configmap/api-b-appsettings created
deployment.apps/api-b created
service/api-b-service created
```
As you can see, here we've deployed `api-b-appsettings` configmap with configuration pointing to the `guinea-pig-lab11-task1-service` service endpoint, one replica of `api-b` and `api-b-service` service exposed at port `8081`. Now, let's test it:

```bash
# Start test pod with interactive shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test api
[ root@curl:/ ]$ curl http://api-b-service:8081/api
[api-b] - OK.
[ root@curl:/ ]$ exit
```

## Task #4 - implement an ingress route

Create `api-b-ingress.yaml` file with the following ingress manifest:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-b-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix      
        backend:
          service:
            name: api-b-service
            port:
              number: 8081
```

```bash
# Deploy api-b-ingress ingress  
kubectl apply -f api-b-ingress.yaml 
ingress.networking.k8s.io/api-b-ingress created
```
It may take some time before private IP address is assigned to the ingress, you can watch the status by running the following command:

```bash
# Get all ingresses
kubectl get ingress -w
NAME              CLASS   HOSTS   ADDRESS   PORTS   AGE
api-b-ingress   nginx   *                 80      17s
api-b-ingress   nginx   *       10.11.0.146   80      51s

# Get api-b-ingress ingresses
kubectl get ingress api-b-ingress

# Describe api-b-ingress ingress
kubectl describe ing api-b-ingress
```

Now, let's test the ingress controller:

```bash
# Get ingress IP address
kubectl get ingress api-b-ingress
NAME            CLASS   HOSTS   ADDRESS       PORTS   AGE
api-b-ingress   nginx   *       10.11.0.146   80      11m

# Start test pod with interactive shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test api endpoint
[ root@curl:/ ]$ curl http://10.11.0.146/api
[api-b] - OK
[ root@curl:/ ]$ exit
```

## Task #5 - implement multiple ingress routes

Create `guinea-pig-lab11-task1-b-ingress.yaml` file with the following ingress manifest:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guinea-pig-lab11-task1-b-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /apia(/|$)(.*)
        pathType: Prefix      
        backend:
          service:
            name: guinea-pig-lab11-task1-service
            port:
              number: 8081
      - path: /apib(/|$)(.*)
        pathType: Prefix      
        backend:
          service:
            name: api-b-service
            port:
              number: 8081
```

In this ingress definition, any characters captured by (.*) will be assigned to the placeholder `$2`, which is then used as a parameter in the [rewrite-target](https://kubernetes.github.io/ingress-nginx/examples/rewrite/) annotation. The ingress definition above will result in the following rewrites:

* `10.11.0.146/apia` rewrites to `10.11.0.146/`
* `10.11.0.146/apia/` rewrites to `10.11.0.146/`
* `10.11.0.146/apia/api` rewrites to `10.11.0.146/api`
* `10.11.0.146/apib/api` rewrites to `10.11.0.146/api`

```bash
# Deploy guinea-pig-lab11-task1-b-ingress ingress  
kubectl apply -f guinea-pig-lab11-task1-b-ingress.yaml 
ingress.networking.k8s.io/guinea-pig-lab11-task1-b-ingress created

# Describe api-b-ingress ingress and check the Rules section
kubectl describe ingress guinea-pig-lab11-task1-b-ingress
```

As you can see in the `Rules`, there are two path pointing to corresponding services

```yaml
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /apia(/|$)(.*)   guinea-pig-lab11-task1-service:8081 (10.11.0.118:80,10.11.0.142:80)
              /apib(/|$)(.*)   api-b-service:8081 (10.11.0.119:80)
```

Now, let's test new ingress controller:

```bash
# Get ingress IP address, but as you already noticed, all ingress will have the same private IP used by NGINX ingress controller
kubectl get ingress guinea-pig-lab11-task1-b-ingress
NAME            CLASS   HOSTS   ADDRESS       PORTS   AGE
api-b-ingress   nginx   *       10.11.0.146   80      11m

# Start test pod with interactive shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test apia endpoint
[ root@curl:/ ]$ curl http://10.11.0.146/apia/api
[guinea-pig-lab11-task1] - OK

# Test apia endpoint
[ root@curl:/ ]$ curl http://10.11.0.146/apib/api
[api-b] - OK

[ root@curl:/ ]$ exit
```

## Useful links

* [Create an ingress controller to an internal virtual network in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/ingress-internal-ip?WT.mc_id=AZ-MVP-5003837)
* [Create an HTTPS ingress controller on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/ingress-tls?WT.mc_id=AZ-MVP-5003837)
* [Create an HTTPS ingress controller and use your own TLS certificates on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls?WT.mc_id=AZ-MVP-5003837)
* [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
* [About Ingress in Azure Kubernetes Service (AKS)](https://vincentlauzon.com/2018/10/10/about-ingress-in-azure-kubernetes-service-aks/)
* [nginx: Default backend](https://kubernetes.github.io/ingress-nginx/user-guide/default-backend/)
* [nginx: Installation with Helm](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)
* [Wait, Which NGINX Ingress Controller for Kubernetes Am I Using?](https://www.nginx.com/blog/wait-which-nginx-ingress-controller-kubernetes-am-i-using/)
* [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
* [Rewrite Target](https://kubernetes.github.io/ingress-nginx/examples/rewrite/)


## Next: scale applications manually

[Go to lab-12](../lab-12/readme.md)