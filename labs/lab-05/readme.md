# lab-05 - Working with Namespaces

In Kubernetes, namespaces provides a mechanism for isolating groups of resources within a single cluster. Names of resources need to be unique within a namespace, but not across namespaces. 

Namespaces are intended for use in environments with many users spread across multiple teams, or projects. For clusters with a few to tens of users, you should not need to create or think about namespaces at all. Start using namespaces when you need the features they provide.

Namespaces provide a scope for names. Names of resources need to be unique within a namespace, but not across namespaces. Namespaces cannot be nested inside one another and each Kubernetes resource can only be in one namespace.

Namespaces are a way to divide cluster resources between multiple users

## Goals

In this lab you will learn how to:

* view namespaces
* set namespace for a request
* create new namespace
* delete namespace

## Task #1 - viewing namespaces

You can list the current namespaces in a cluster using:

```bash
# View all namespaces
kubectl get namespace
# or 
kubectl get namespaces
# or
kubectl get ns

NAME              STATUS   AGE
calico-system     Active   102m
default           Active   104m
flux-system       Active   104m
kube-node-lease   Active   104m
kube-public       Active   104m
kube-system       Active   104m
tigera-operator   Active   104m
```

## Task #2 - set namespace for a request

To set the namespace for a current request, use the `--namespace` or `-n` flag.

```bash
# Get all pods from kube-system namespace
kubectl get pods --namespace kube-system
# or
kubectl get pods --namespace=kube-system
# or
kubectl get pods -n kube-system
```

if you want to get resources from all namespaces, use `--all-namespaces` or `-A` flag

```bash
# Get all pods from all namespaces
kubectl get po --all-namespaces
# or 
kubectl get pods -A
```

## Task #2 - create new namespaces using `kubectl create namespace` command

```bash
# Create new foobar namespace
kubectl create namespace foobar

# Check if namespace was created
kubectl get ns foobar

# Check if there are any pods in foobar namespace
kubectl get po -n foobar
No resources found in foobar namespace.

# Deploy guinea-pig pod into foobar namespace
kubectl -n foobar run foobar-pod --image eratewsznjnxaunsoy42acr.azurecr.io/guinea-pig:v1

# Check if there are any pods in foobar namespace
kubectl get po -n foobar
NAME         READY   STATUS    RESTARTS   AGE
foobar-pod   1/1     Running   0          46s

# Delete foobar-pod pod from foobar namespace
kubectl -n foobar delete po foobar-pod
pod "foobar-pod" deleted
```

## Task #3 - create new namespaces using manifest file

Create new `lab-05-task3.yaml` manifest file with the following content

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: barfoo
```

Then deploy manifest by running

```bash
# Create new namespace
kubectl apply -f lab-05-task3.yaml
namespace/barfoo created

# Check if namespace was created
kubectl get ns barfoo
NAME     STATUS   AGE
barfoo   Active   36s
```

## Task #4 - delete namespace

You can delete a namespace with 

```bash
# Delete foobar namespace
kubectl delete namespace foobar
# or 
kubectl delete ns foobar

namespace "foobar" deleted
```

If namespace was created from with manifest file, you can delete it by using 

```bash
# Delete barfoo namespace 
kubectl delete -f lab-05-task3.yaml
namespace "barfoo" deleted
```

## Useful links

* [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
* [Creating a new namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#creating-a-new-namespace)
* [Deleting a namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#deleting-a-namespace)
* [kubectl create namespace](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-namespace-em-)

## Next: Working with Kubernetes Resource Management

[Go to lab-06](../lab-06/readme.md)