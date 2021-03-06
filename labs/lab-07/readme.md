# lab-07 - Configuring Readiness and Liveness probes

Kubernetes supports monitoring applications in the form of readiness and liveness probes. 

### Liveness probes
Liveness probe indicates a container is "alive". Many applications running for long periods of time eventually transition to broken states, and cannot recover except by being restarted. Kubernetes provides liveness probes to detect and remedy such situations. If a liveness probe fails multiple times the container will be restarted. Liveness probes that continue to fail will cause a Pod to enter a crash loop.

### Readiness probes
Sometimes, applications are temporarily unable to serve traffic. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. In such cases, you don't want to kill the application, but you don't want to send it requests either. Kubernetes provides readiness probes to detect and mitigate these situations. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.

Readiness and liveness probes can be used in parallel for the same container. Using both can ensure that traffic does not reach a container that is not ready for it, and that containers are restarted when they fail.

In this lab we will extend our application with additional readiness and liveness endpoints and extend pod definition with readiness and liveness probes.

## Goals

In this lab you will learn how to:

* create Pods with readiness and liveness probes
* troubleshoot failing readiness and liveness probes

## Task #1 - configure your Windows Terminal

As before, split your terminal in two. At the right-hand window, run `kubectl get po -w` command and at the left-hand window execute labs commands.

## Task #2 - add Liveness probe

Create new yaml pod definition file `lab-07-healthy.yaml` with the following content. 
Note that there is new `livenessProbe` section in the definition

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lab-07-healthy
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
```

Now, deploy it

```bash
# Deploying lab-07-healthy.yaml
kubectl apply -f lab-07-healthy.yaml
pod/lab-07-healthy created
```

Check the `lab-07-healthy` logs

```bash
# Stream logs from lab-07-healthy pod
kubectl logs lab-07-healthy -f
[20:20:56 INF] [lab-07] - always healthy
[20:20:59 INF] [lab-07] - always healthy
[20:21:02 INF] [lab-07] - always healthy
[20:21:05 INF] [lab-07] - always healthy
[20:21:08 INF] [lab-07] - always healthy
[20:21:11 INF] [lab-07] - always healthy
[20:21:14 INF] [lab-07] - always healthy
[20:21:17 INF] [lab-07] - always healthy
```

As you can see, the `/health` endpoint is now called every 3 seconds (defined at `periodSeconds` field in the manifest).

The `periodSeconds` field specifies that the kubelet should perform a liveness probe every 3 seconds. The `initialDelaySeconds` field tells the kubelet that it should wait 3 seconds before performing the first probe. To perform a probe, the `kubelet` sends an HTTP GET request to the server that is running in the container and listening on port 80. If the handler for the server's `/health` path returns a success code, the `kubelet` considers the container to be alive and healthy. If the handler returns a failure code, the `kubelet` kills the container and restarts it. 

Let's try to simulate such a situation.

## Task #3 - add Liveness probe with unhealthy endpoint

For this task let's use `/health/almost_healthy` endpoint as a `livenessProbe` get request. Check implementation of `AlmostHealthy` method at `src\GuineaPig\Controllers\HealthController.cs` file. 

It contains some extra "logic":
* for the first 10 seconds the app is alive and the `/health/almost_healthy` handler returns a status of 200
* after 10 sec, the handler returns a status of 500

```c#
...
var secondsFromStart = Timekeeper.GetSecondsFromStart();
_logger.LogInformation($"{secondsFromStart} seconds from start...");
var secondsToWait = 10;
if (secondsFromStart < secondsToWait)
{
    _logger.LogInformation($"< {secondsToWait} seconds -> response with 200");
    return Ok("[lab-07] - healthy first 10 sec");
}

_logger.LogInformation($"> {secondsToWait} seconds -> response with 500");
return StatusCode(500);
```

Create new manifest file called `lab-07-almost-healthy.yaml` with the following content. Note that `path:` is now points to `/health/almost_healthy`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lab-07-almost-healthy
spec:
  containers:
  - name: api
    image: eratewsznjnxaunsoy42acr.azurecr.io/guinea-pig:v1
    imagePullPolicy: IfNotPresent
    resources: {}
    livenessProbe:
      httpGet:
        path: /health/almost_healthy
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 3    
```

Deploy it

```bash
# Deploy lab-07-almost-healthy.yaml
kubectl apply -f lab-07-almost-healthy.yaml
pod/lab-07-almost-healthy created
```

Observe pod behavior at the monitoring window with `kubectl get po -w` command. 

The `kubelet` starts performing health checks 3 seconds after the container starts. So the first couple of health checks will succeed. But after 10 seconds, the health checks will fail, and the kubelet will kill and restart the container. After several attempts, pod will go into `CrashLoopBackOff` state.

Your "watching" log should show something similar to 

```bash
lab-07-almost-healthy   0/1     Pending   0          0s
lab-07-almost-healthy   0/1     Pending   0          0s
lab-07-almost-healthy   0/1     ContainerCreating   0          0s
lab-07-almost-healthy   1/1     Running             0          2s
lab-07-almost-healthy   1/1     Running             1          12s
lab-07-almost-healthy   1/1     Running             2          20s
lab-07-almost-healthy   0/1     CrashLoopBackOff    2          29s
lab-07-almost-healthy   1/1     Running             3          43s
lab-07-almost-healthy   1/1     Running             4          54s
lab-07-almost-healthy   0/1     CrashLoopBackOff    4          63s
```

If you get pod description, under the `Events:` section you should see that pod was `Unhealthy` because `Liveness probe failed: HTTP probe failed with statuscode: 500` and then pod was killed because `Container api failed liveness probe, will be restarted`.

```bash
# Get pod description
kubectl describe po lab-07-almost-healthy
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Killing    42s (x3 over 78s)   kubelet            Container api failed liveness probe, will be restarted
  Normal   Started    41s (x4 over 95s)   kubelet            Started container api
  Warning  Unhealthy  30s (x10 over 84s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
```

## Task #4 - add Readiness probe

Readiness probes are configured similarly to liveness probes. The only difference is that you use the `readinessProbe` field instead of the `livenessProbe` field.

Create new manifest file `lab-07-ready.yaml` with the following content. 
Note that you should use your ACR url for `image` field and there is additional `readinessProbe` section 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lab-07-ready
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
```

Now, deploy it

```bash
# Deploying lab-07-ready.yaml
kubectl apply -f lab-07-ready.yaml
pod/lab-07-ready created
```

Check the `lab-07-ready` logs

```bash
# Stream logs from lab-07-ready pod
kubectl logs lab-07-ready -f
[20:30:42 INF] [lab-07] - always ready
[20:30:43 INF] [lab-07] - always ready
[20:30:43 INF] [lab-07] - always healthy
[20:30:46 INF] [lab-07] - always ready
[20:30:46 INF] [lab-07] - always healthy
[20:30:49 INF] [lab-07] - always healthy
[20:30:49 INF] [lab-07] - always ready
[20:30:52 INF] [lab-07] - always healthy
[20:30:52 INF] [lab-07] - always ready
[20:30:55 INF] [lab-07] - always ready
[20:30:55 INF] [lab-07] - always healthy
[20:30:58 INF] [lab-07] - always ready
[20:30:58 INF] [lab-07] - always healthy
[20:31:01 INF] [lab-07] - always healthy
[20:31:01 INF] [lab-07] - always ready
```

As you can see, both  `/health` and `/readiness` endpoints are called every 3 seconds.

## Task #5 - add Readiness probe with unstable endpoint

For this task we will use `/readiness/unstable` endpoint for `livenessProbe` get request. Check implementation of `Unstable` method at `src\GuineaPig\Controllers\ReadinessController.cs` controller. 
It contains extra logic that response status changes every minute. That is - first minute - 200 and next minute - 500, next minute - 200 etc...

Create manifest file `lab-07-ready-unstable.yaml` with the following content. 
Note that you should use your ACR url for `image` field and `readinessProbe` points to `/readiness/unstable` endpoint

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lab-07-ready-unstable
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
        path: /readiness/unstable
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 3               
```

Now, deploy it

```bash
# Deploying lab-07-ready-unstable.yaml
kubectl apply -f lab-07-ready-unstable.yaml
pod/lab-07-ready-unstable created
```
wait for about 2-3 while observing what is happening at the "watch" window. You should see similar behavior:

```bash
NAME                    READY   STATUS             RESTARTS        AGE
lab-07-ready-unstable   0/1     Running            0               15s
lab-07-ready-unstable   1/1     Running            0               63s
lab-07-ready-unstable   0/1     Running            0               2m9s
lab-07-ready-unstable   1/1     Running            0               3m3s
```

as you can see, it periodically (every minute) changes `Ready` field from `1/1` to `0/1`, the `Status` always shows `Running` and it never goes into the `CrashLoopBackOff` status.

Check the pod description 

```bash
# Get pod description
kubectl describe po lab-07-ready-unstable
...
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Created    13m                    kubelet            Created container api
  Normal   Started    13m                    kubelet            Started container api
  Warning  Unhealthy  3m41s (x100 over 13m)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 500
  ```

The sate was `Unhealthy` 100 times over the last 13 min with reason `Readiness probe failed: HTTP probe failed with statuscode: 500`

## Useful links

* [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

## Next: Deployments

[Go to lab-08](../lab-08/readme.md)