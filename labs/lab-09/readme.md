# lab-09 - Creating and Managing Services

## Estimated completion time - xx min

Service in Kubernetes is an abstract way to expose an application running on a set of Pods as a network service.
Kubernetes gives Pods their own IP addresses and a single DNS name for a set of Pods, and can load-balance across them.

## Goals

In this lab you will learn how to:

* create Kubernetes Service using `kubectl expose` command
* create Kubernetes Service using yaml definition
* update Kubernetes Service using yaml definition
* delete Kubernetes Service

## Task #1 - prepare your lab environment

Split your terminal in two. At the right-hand window, run `kubectl get svc -w` command while at the left-hand window execute labs commands.

## Task #2 - deploy Deployment from lab-08

If you completed `lab-08` and deleted Deployment you created during this lab, re-deploy it again

```bash
# Deploy lab-08-task3-deployment.yaml Deployment
kubectl apply -f lab-08-task3-deployment.yaml

# Check that rollout status is "successfully rolled out"
kubectl rollout status deployment/lab-08-task3
deployment "lab-08-task3" successfully rolled out
```

## Task #3 - Create Service using `kubectl expose` command

```bash
# Expose deployment lab-08-task3 as a new Kubernetes service guinea-pig-service-1
kubectl expose deployment lab-08-task3 --name=guinea-pig-service-1 --port=80 --target-port=80
service/guinea-pig-service-1 exposed

# Get all services 
kubectl get services 
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
guinea-pig-service-1   ClusterIP   10.0.169.148   <none>        80/TCP    22m
kubernetes       ClusterIP   10.0.0.1       <none>        443/TCP   4d

# Show services with labels (note, that I use alias svc this time)
kubectl get svc --show-labels
NAME                   TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   LABELS
guinea-pig-service-1   ClusterIP   10.0.227.41   <none>        80/TCP    29s   app=lab-08-task3
kubernetes             ClusterIP   10.0.0.1      <none>        443/TCP   10h   component=apiserver,provider=kubernetes

# Get service guinea-pig-service-1 yaml definition
kubectl get svc guinea-pig-service-1 -oyaml

# Get service guinea-pig-service-1 description 
kubectl describe svc guinea-pig-service-1
Name:              guinea-pig-service-1
Namespace:         default
Labels:            app=lab-08-task3
Annotations:       <none>
Selector:          app=lab-08-task3
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.0.227.41
IPs:               10.0.227.41
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.1.0.27:80,10.1.0.53:80,10.1.0.61:80
Session Affinity:  None
Events:            <none>
```

Now, let's test our service.

```bash
# Get service CLUSTER-IP
kubectl get svc guinea-pig-service-1 
NAME                   TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
guinea-pig-service-1   ClusterIP   10.0.227.41   <none>        80/TCP    2m37s

# Start our test shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test our service using IP (you should use your IP)
[ root@curl:/ ]$ curl http://10.0.227.41/api

# Test our service using service DNS name
[ root@curl:/ ]$ curl http://guinea-pig-service-1/api

# Test our service using service full DNS name
[ root@curl:/ ]$ curl http://guinea-pig-service-1.default.svc.cluster.local/api

# Run "test load" with watch command. It will run "curl http://guinea-pig-service-1/weatherforecast" command every second until we stop it
[ root@curl:/ ]$ watch -n 1 curl http://guinea-pig-service-1/api
```

Keep the test running and open|split new terminal and scale Deployment `lab-08-task3` down to 0 and see what will happen with our test.

```bash
# Scale lab-08-task3 deployment to 0 replicas
kubectl scale deployment lab-08-task3 --replicas=0
deployment.apps/lab-08-task3 scaled
```
you should see that `curl: (7) Failed to connect to guinea-pig-service-1 port 80: Connection refused`. Now scale it back to 3 replicas

```bash
# Scale lab-08-task3 deployment to 3 replicas
kubectl scale deployment lab-08-task3 --replicas=3
deployment.apps/lab-08-task3 scaled
```
and our app should be back to business.

```bash
# Stop the watch command with Ctrl+C and leave the shell
[ root@curl:/ ]$exit
```

## Task #4 - Create service using yaml definition file

Create new `lab-09-guinea-pig-service-2.yaml` manifest file with the following content

```yaml
apiVersion: v1
kind: Service
metadata:
  name: guinea-pig-service-2
  labels:
    app: lab-08-task3
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: lab-08-task3
  type: ClusterIP
```

Deploy it using `kubectl apply` command

```bash
# Deploy lab-09-guinea-pig-service-2.yaml service
kubectl apply -f .\lab-09-guinea-pig-service-2.yaml
service/guinea-pig-service-2 created

# Get service 
kubectl get svc guinea-pig-service-2 

# Get service guinea-pig-service-2 description 
kubectl describe svc guinea-pig-service-2

# Start test shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test service
[ root@curl:/ ]$ curl http://guinea-pig-service-2/api

# Leave the shell
[ root@curl:/ ]$exit
```

## Task #6 - change service port

Now let's change Service port to `8081`. Edit `lab-09-guinea-pig-service-2.yaml` and replace `port: 80` with `port: 8081`, deploy and test it.

```bash
# Deploy lab-09-guinea-pig-service-2.yaml service
kubectl apply -f .\lab-09-guinea-pig-service-2.yaml
service/guinea-pig-service-2 configured

# Get service and check that PORT(S) field is now showing 8081/TCP 
kubectl get svc guinea-pig-service-2 
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
guinea-pig-service-2   ClusterIP   10.0.164.163   <none>        8081/TCP   16m

# Start test shell
kubectl run curl -i --tty --rm --restart=Never --image=radial/busyboxplus:curl -- sh

# Test the service. Note that it doesn't work since we changed the port
[ root@curl:/ ]$ curl http://guinea-pig-service-2/api

# Test using port :8081
[ root@curl:/ ]$ curl http://guinea-pig-service-2:8081/api

# Leave the shell
[ root@curl:/ ]$exit
```

## Task #7 - delete service

There are several ways you can delete service

```bash
# Delete guinea-pig-service-1 Service using `kubectl delete svc ` command
kubectl delete svc guinea-pig-service-1
service "guinea-pig-service-1" deleted

# Delete guinea-pig-service-2 Service using yaml definition file
kubectl delete -f .\lab-09-guinea-pig-service-2.yaml
service "guinea-pig-service-2" deleted
```

## Useful links

* [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/)
* [Use a Service to Access an Application in a Cluster](https://kubernetes.io/docs/tasks/access-application-cluster/service-access-application-cluster/)
* [kubectl expose](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose)

## Next: Configmaps and secrets

[Go to lab-10](../lab-10/readme.md)
