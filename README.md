# Kubernetes (k8s) POC

##### Table of Contents  
[Intro](#intro)<br/>
[Service container](#service-container)<br/>
[Install Minikube server](#install-minikube)<br/>
[Deploy k8spoc service in Kubernetes using command line](#deploy-cmd)<br/>
[Deploy k8spoc service in Kubernetes using yaml files](#deploy-yaml)<br/>
[Update Deployment (Scaling pods)](#deploy-update)<br/>
[Deploy k8spoc service in Kubernetes using Helm package manager](#deploy-helm)<br/>
[Testing HA](#testing-ha)<br/>
[Istio (Service Mesh) integration](#istio)


## Intro <a name="intro"/>

This document describes the steps to deploy GetCustomerDetails v1.1.0-SNAPSHOT in a local minikube cluster, the target of this POC is understand the kubernetes behavior, how to launch a new service, manage this deployment, update the containers and scaling the services

To understand how to Kubernetes operates, we recommend you to read: [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/) and [Concepts](https://kubernetes.io/docs/concepts/)


## Service container <a name="service-container"/>
Kubernetes uses docker images to create a pod, we build a docker container for GetCustomerDetails v1.1.0-SNAPSHOT, this container is basedin amazon-corretto image and exposes the 8081 port.

The Dockerfile file can be find in ***docker/Dockerfile***

### Create the image
1. Change to project root
```bash
   cd /path/to/project/k8spoc
```
2. build the image, run dockerbuild.sh
```bash
   sh ./bin/dockerbuild.sh
```
  *Important:*
  * run the build shell from project root
  * Dockerfile uses the follow, files to build the image:
    * target/getCustomerDetailsService-1.1.0-SNAPSHOT-fat.jar
    * cfg/cluster.xml
    * bin/entrypoint.sh

### Publish the image in **DockerHub**
1. Tag the image with the format: ***\<dockerhub user\>\/\<docker hub repo\>:X.Y.Z***
  ```bash
     docker tag getcustomerdetails:1.1.0-SNAPSHOT hectormaoglb/k8spoc:1.1.0-SNAPSHOT
  ```
  Where:
  * ***getcustomerdetails:1.1.0-SNAPSHOT***: name and version of the local container
  * ***hectormaoglb***: docker hub user
  * ***k8spoc***: docker hub repo
  * ***1.1.0-SNAPSHOT***: tag or version

  > the docker tag command format is:
  ```bash
     docker tag <src image> <tag>
  ```
2. Login into DockerHub
  ```bash
  docker login -u hectormaoglb
  ```
  Where:
  * ***hectormaoglb***: docker hub user


3. Publish the image into DockerHub Repo
  ```bash
  docker push hectormaoglb/k8spoc:1.1.0-SNAPSHOT
  ```

## Install Minikube server <a name="install-minikube"/>
to install the a local kubernetes server to practice, we used minikube implementation and follow the instructions in [Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

In my case, I can't install virtualbox as Hypervisor driver, then I install minikube with none vm-driver [Running Minikube with vm-diver none](https://medium.com/@nieldw/running-minikube-with-vm-driver-none-47de91eab84c).
> **WARNING:** IT IS RECOMMENDED NOT TO RUN THE NONE DRIVER ON PERSONAL WORKSTATIONS.
>
> *The ‘none’ driver will run an insecure kubernetes apiserver as root that may leave the host vulnerable to CSRF attacks*

> **NOTE:** Some minikube operations must be executed as root user

## Deploy k8spoc service in Kubernetes using command line <a name="deploy-cmd"/>
To deploy the contenerized service in a local minikube, we use this tutorial [Hello Minukube](https://kubernetes.io/docs/tutorials/hello-minikube/)
1. Start minikube service with vm-driver none as root
  ```bash
  sudo sh bin/start_minikube.sh
  ```
2. Open Minikube Dashboard
  ```bash
  sudo minikube dashboard
  ```
  into command logs you can find the link to the kubernetes dashboard, in this case the URL was
  ```bash
  http://127.0.0.1:37293/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/
  ```
3. Create a new deployment/pod
  ```bash
  kubectl create deployment k8spoc-deploy --image=hectormaoglb/k8spoc:1.1.0-SNAPSHOT
  ```
4. Get deployments
  ```bash
  h.gonzalez@CO-IT004729:~$ kubectl get deployments
  NAME            READY   UP-TO-DATE   AVAILABLE   AGE
  k8spoc-deploy   1/1     1            1           15s
  ```
5. Get pods
  ```bash
  h.gonzalez@CO-IT004729:~$ kubectl get pods
  NAME                             READY   STATUS    RESTARTS   AGE
  k8spoc-deploy-544ff49fbd-gqtc2   1/1     Running   0          37s
  ```
6. Check cluster events
  ```bash
  h.gonzalez@CO-IT004729:~$ kubectl get events
  LAST SEEN   TYPE     REASON                    OBJECT                                MESSAGE
  58s         Normal   Scheduled                 pod/k8spoc-deploy-544ff49fbd-gqtc2    Successfully assigned default/k8spoc-deploy-544ff49fbd-gqtc2 to minikube
  57s         Normal   Pulled                    pod/k8spoc-deploy-544ff49fbd-gqtc2    Container image "hectormaoglb/k8spoc:1.1.0-SNAPSHOT" already present on machine
  57s         Normal   Created                   pod/k8spoc-deploy-544ff49fbd-gqtc2    Created container k8spoc
  57s         Normal   Started                   pod/k8spoc-deploy-544ff49fbd-gqtc2    Started container k8spoc
  58s         Normal   SuccessfulCreate          replicaset/k8spoc-deploy-544ff49fbd   Created pod: k8spoc-deploy-544ff49fbd-gqtc2
  58s         Normal   ScalingReplicaSet         deployment/k8spoc-deploy              Scaled up replica set k8spoc-deploy-544ff49fbd to 1
  26m         Normal   Starting                  node/minikube                         Starting kubelet.
  26m         Normal   NodeHasSufficientMemory   node/minikube                         Node minikube status is now: NodeHasSufficientMemory
  26m         Normal   NodeHasNoDiskPressure     node/minikube                         Node minikube status is now: NodeHasNoDiskPressure
  26m         Normal   NodeHasSufficientPID      node/minikube                         Node minikube status is now: NodeHasSufficientPID
  26m         Normal   NodeAllocatableEnforced   node/minikube                         Updated Node Allocatable limit across pods
  26m         Normal   RegisteredNode            node/minikube                         Node minikube event: Registered Node minikube in Controller
  26m         Normal   Starting                  node/minikube                         Starting kube-proxy.
  ```
7. Create the service

  By default, the POD is only accessible by kubernetes internal IP, to make it accessible from outside you need to execute expose command
  ```bash
  kubectl expose deployment k8spoc-deploy --type=LoadBalancer --port=8081
  ```
8. Check services
  ```bash
  h.gonzalez@CO-IT004729:~$ kubectl get services
  NAME            TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
  k8spoc-deploy   LoadBalancer   10.102.115.41   <pending>     8081:30222/TCP   4s
  kubernetes      ClusterIP      10.96.0.1       <none>        443/TCP          38m
  ```
  please check the port mapping, now it's possible to consume REST API of our service using the port 30222:
  ```bash
  curl -X POST \
    http://192.168.1.118:30222/ev/getCustomerDetails \
    -H 'Cache-Control: no-cache' \
    -H 'Content-Type: application/json' \
    -H 'Postman-Token: 4025dd41-7a0c-48d1-b61a-2343c297b2a2' \
    -d '{
	  "userToken" : "8543c63333423b0d68af2f50195eb6da6402342b"
    }'
  ```

## Deploy k8spoc service in Kubernetes using yaml files <a name="deploy-yaml"/>

1. Start minikube service with vm-driver none as root
  ```bash
  sudo sh bin/start_minikube.sh
  ```
2. Open Minikube Dashboard
  ```bash
  sudo minikube dashboard
  ```
  into command logs you can find the link to the kubernetes dashboard, in this case the URL was
  ```bash
  http://127.0.0.1:37293/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/
  ```
3. Create deployment using k8spoc-deployment.yaml file
  ```bash
  kubectl apply -f kubernetes/k8spoc-deployment.yaml
  ```
4. Check deployment
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get deployments
  NAME                READY   UP-TO-DATE   AVAILABLE   AGE
  k8spoc-deployment   2/2     2            2           15s
  ```
5. Create the service using k8spoc-service.yaml
  ```bash
  kubectl apply -f kubernetes/k8spoc-service.yaml
  ```
6. Check services
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get services
  NAME             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
  k8spoc-service   LoadBalancer   10.102.31.140   <pending>     8081:32458/TCP   12s
  kubernetes       ClusterIP      10.96.0.1       <none>        443/TCP          7h23m
  ```
  please use the k8spoc-service PORT to consume the service
7. Consume the service
  ```bash
  curl -X POST \
    http://192.168.1.118:32458/ev/getCustomerDetails \
    -H 'Cache-Control: no-cache' \
    -H 'Content-Type: application/json' \
    -H 'Postman-Token: 20ccdf44-19b2-4d4c-bf96-4f23a8faa32b' \
    -d '{
  	"userToken" : "8543c63333423b0d68af2f50195eb6da6402342b"
  }'
  ```

## Update Deployment (Scaling pods) <a name="deploy-update"/>
1. Edit k8spoc-deployment.yaml set replicas in 3
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: k8spoc-deployment
    labels:
      app: k8spoc
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: k8spoc
    template:
      metadata:
        labels:
          app: k8spoc
      spec:
        containers:
        - name: k8spoc
          image: hectormaoglb/k8spoc:1.1.0-SNAPSHOT
          ports:
          - containerPort: 8081
  ```
2. Apply the change in kubernetes
  ```bash
  kubectl apply -f kubernetes/k8spoc-deployment.yaml
  ```
4. Check deployment
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get deployments
  NAME                READY   UP-TO-DATE   AVAILABLE   AGE
  k8spoc-deployment   3/3     3            3           3h
  ```

## Deploy k8spoc service in Kubernetes using Helm package manager <a name="deploy-helm"/>
Helm tool is the kubernetes package manager, it's simplify the pods and service deploy and manage into kubernetes cluster [Helm Home Page](https://helm.sh/).

Before you starts with this steps, We recommend you to read the Helm basic concepts [Three Big Concepts](https://helm.sh/docs/using_helm/#three-big-concepts)

1. Install helm
  to install helm binary packages we have followed this doc [Installing Helm](https://helm.sh/docs/using_helm/#installing-helm)
2. Install Helm Server (Tiller)
  ```bash
  helm init
  ```
3. Check the tiller service IP
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc/helm$ kubectl get pods --namespace kube-system -o wide
  NAME                                    READY   STATUS    RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES
  coredns-5c98db65d4-54ppr                1/1     Running   20         23h   172.17.0.6      minikube   <none>           <none>
  coredns-5c98db65d4-7w27z                1/1     Running   20         23h   172.17.0.5      minikube   <none>           <none>
  etcd-minikube                           1/1     Running   1          23h   10.132.10.235   minikube   <none>           <none>
  kube-addon-manager-minikube             1/1     Running   1          23h   10.132.10.235   minikube   <none>           <none>
  kube-apiserver-minikube                 1/1     Running   21         23h   10.132.10.235   minikube   <none>           <none>
  kube-controller-manager-minikube        1/1     Running   8          23h   10.132.10.235   minikube   <none>           <none>
  kube-proxy-f68h8                        1/1     Running   1          23h   10.132.10.235   minikube   <none>           <none>
  kube-scheduler-minikube                 1/1     Running   8          23h   10.132.10.235   minikube   <none>           <none>
  kubernetes-dashboard-7b8ddcb5d6-4dfg2   1/1     Running   2          23h   172.17.0.3      minikube   <none>           <none>
  storage-provisioner                     1/1     Running   2          23h   10.132.10.235   minikube   <none>           <none>
  tiller-deploy-5dc46c877-dbdg2           1/1     Running   1          23h   172.17.0.2      minikube   <none>           <none>
  ```
4. Set environment variable to find tiller server
  ```bash
  export HELM_HOST=172.17.0.2:44134
  ```
5. Create a Chart Template
  ```bash
    helm create k8spoc
  ```
  This command create a directory structure with an empty service packages

6. Edit Chart files according service to deploy, you can see the edited files to deploy k8spoc service in ***helm/k8spoc***

7. Validate the chart
  ```bash
    helm lint k8spoc
  ```

8. Package the chart
  ```bash
    helm package k8spoc
  ```
  This command creates a tgz file with the chart

9. Install the chart
  ```bash
    helm install k8spoc-1.1.0-SNAPSHOT.tgz
  ```

10. Check the Release
  ```bash
    h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc/helm$ helm list
    NAME           	REVISION	UPDATED                 	STATUS  	CHART                	APP VERSION   	NAMESPACE
    wayfaring-hyena	1       	Fri Jun 28 10:04:41 2019	DEPLOYED	k8spoc-1.1.0-SNAPSHOT	1.1.0-SNAPSHOT	default
  ```

11. Delete release (service)
```bash
  helm delete wayfaring-hyena
```
### Update a Release
  To update or changing the config of a deployed release, you need to execute
  ```bash
    helm upgrade -f helm/new_values.yaml wayfaring-hyena helm/k8spoc-1.1.0-SNAPSHOT.tgz
  ```
  Where:
  * *new_values.yaml* file has the new configuration params
  * *wayfaring-hyena* name the Release
  * *helm/k8spoc-1.1.0-SNAPSHOT.tgz* Helm Chart
  ***Note***: In this case we update the replicas to 3

## Testing HA <a name="testing-ha"/>
To test the service HA, we tested 2 different scenarios:
1. Delete a cluster pod (container)
2. Kill java process of a container

In both cases the cluster must guarantee the service operation, it replaces the dead container with another one (Scenario 1), or it restarts the unhealthy pod (Scenario 2)
### Delete a cluster pod
1. check initial state
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get all
  NAME                                          READY   STATUS    RESTARTS   AGE
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-4f29r   1/1     Running   0          13m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-8p8f8   1/1     Running   0          80m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-qtmfh   1/1     Running   0          13m

  NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
  service/kubernetes               ClusterIP      10.96.0.1      <none>        443/TCP          25h
  service/wayfaring-hyena-k8spoc   LoadBalancer   10.102.50.42   <pending>     8081:30443/TCP   80m

  NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/wayfaring-hyena-k8spoc   3/3     3            3           80m

  NAME                                                DESIRED   CURRENT   READY   AGE
  replicaset.apps/wayfaring-hyena-k8spoc-657c9c6ccf   3         3         3       80m
  ```
  We have 3 pods of the same service release
2. Delete a pod
  ```bash
    kubectl delete pods pod/wayfaring-hyena-k8spoc-657c9c6ccf-4f29r
  ```
3. Check the new state
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get all
  NAME                                          READY   STATUS        RESTARTS   AGE
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-4f29r   1/1     Terminating   0          14m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-8p8f8   1/1     Running       0          81m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-c4v2q   0/1     Running       0          12s
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-qtmfh   1/1     Running       0          14m

  NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
  service/kubernetes               ClusterIP      10.96.0.1      <none>        443/TCP          25h
  service/wayfaring-hyena-k8spoc   LoadBalancer   10.102.50.42   <pending>     8081:30443/TCP   81m

  NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/wayfaring-hyena-k8spoc   2/3     3            2           81m

  NAME                                                DESIRED   CURRENT   READY   AGE
  replicaset.apps/wayfaring-hyena-k8spoc-657c9c6ccf   3         3         2       81m
  ```
  The deleted pod was marked as Terminating and new one was created (*wayfaring-hyena-k8spoc-657c9c6ccf-c4v2q*) to keep the desired state (3 running replicas)

  ***Important:*** while the pod was deleted, we consume the services using the postman run feature, and the results were: of 1000 request only had one error, but this error was caused the third party timeout

### Kill java process
1. Choose a container
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ docker ps -a
  CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS                      PORTS               NAMES
  46a5b0bb2e68        c1715d10940c                    "/bin/sh -c ${MICROS…"   7 minutes ago       Up 7 minutes                                    k8s_k8spoc_wayfaring-hyena-k8spoc-657c9c6ccf-bbdcb_default_d3b05c8e-ed80-4130-81bf-6674575c4ab4_0
  ```

2. Get container Java process ID
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ docker top 46a5b0bb2e68
  UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
  root                8451                8423                0                   11:34               ?                   00:00:00            /bin/sh -c ${MICROSERVICE_HOME}/entrypoint.sh
  root                8480                8451                1                   11:34               ?                   00:00:14            java -DIP=127.0.0.1 -Dvertx.metrics.options.enabled=true -Dhazelcast.cluster.enabled=true -Dhazelcast.cluster.hostname=127.0.0.1 -D_hazelcast.client-mode=true -Dhazelcast.cluster-config-file=/opt/microservice/cluster.xml -Devergent.HMAC.key=Y9o7GiSU9bb8Uva9RU9n1SR0il0aksmi -Devergent.AES.key=SAvBRCaDUErTuInK -jar /opt/microservice/getCustomerDetailsService-1.1.0-SNAPSHOT-fat.jar
  ```
3. kill java process
  ```bash
  sudo kill -9 8480
  ```
4. Check the new state
  ```bash
  h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc$ kubectl get all
  NAME                                          READY   STATUS    RESTARTS   AGE
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-9nlcp   1/1     Running   0          139m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-bbdcb   1/1     Running   1          137m
  pod/wayfaring-hyena-k8spoc-657c9c6ccf-qqxgk   1/1     Running   0          138m

  NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
  service/kubernetes               ClusterIP      10.96.0.1      <none>        443/TCP          28h
  service/wayfaring-hyena-k8spoc   LoadBalancer   10.102.50.42   <pending>     8081:30443/TCP   3h47m

  NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/wayfaring-hyena-k8spoc   3/3    https://istio.io/docs/concepts/what-is-istio/  3            3           3h47m

  NAME                                                DESIRED   CURRENT   READY   AGE
  replicaset.apps/wayfaring-hyena-k8spoc-657c9c6ccf   3         3         3       3h47m
  ```
  Please check the second pod, the RESTARTS conter is now in 1, kubernetes restart the container and keep 3 replicas running

## Istio (Service Mesh) integration <a name="istio"/>

Istio lets you connect, secure, control, and observe services. [What is Istio?](https://istio.io/docs/concepts/what-is-istio/)

if you want to the complete and official Istio Documentation please visit: [Istio Home Page](https://istio.io/)

Before you start with this tutorial, I recommend you read the Istio basic concepts [Istio Concepts](https://istio.io/docs/concepts/)

### Installing (Integrating) Istio into kubernetes cluster

To install or integrate the Istio service mesh into Kubernetes cluster, we have been followed the next steps

1. Prepare Minikube
  a. Install kvm hypervisor driver
      To install kvm we followed this tutorial [Install KVM Ubuntu 18.04](https://www.linuxtechi.com/install-configure-kvm-ubuntu-18-04-server/)
  b. Start minikube server using kvm2 driver [Minikube for Istio](https://istio.io/docs/setup/kubernetes/platform-setup/minikube/)
      In my case, I couldn't set memory in 16GB, I used the follow command to launch Minikube
      ```bash
         minikube start --memory=8192 --cpus=4 --vm-driver=kvm2
      ```
2. Install Istio using Helm [Istio Helm Installation](https://istio.io/docs/setup/kubernetes/install/helm/)

3. Set default namespace with sidecar autoinjection label
```bash
  kubectl label namespace default istio-injection=enabled
```
This label causes that all pods launched in this namespace will be injected with the envoy proxy (sidecar) to be managed by Istio Control Plane

4. Deploy k8spoc service into Istio Service Mesh
```bash
  helm install helm/k8spoc-1.1.0-SNAPSHOT.tgz -n k8spoc
```

5. Check service into cluster
```bash
  kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=k8spoc -o jsonpath='{.items[0].metadata.name}') -c k8spoc -- curl http://k8spoc:8081
```
6. Create a gateway and virtual to consume service outside mesh
```bash
kubectl apply -f istio/k8spoc-gateway.yaml
```
This gateway causes that the k8spoc services be accessible from outside of the cluster
7. Check ingress gateway IP
```bash
h.gonzalez@CO-IT004729:~/Dev/repos/k8spoc/helm/k8spoc$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.110.167.41   10.110.167.41   15020:32515/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:31677/TCP,15030:30892/TCP,15031:31180/TCP,15032:31905/TCP,15443:31179/TCP   5h13m
```
get the **EXTERNAL_IP**
8. Check the service
```bash
curl -X POST \
  http://10.110.167.41/ev/getCustomerDetails \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 08b647e4-2b22-45ac-a1c9-afe1e3cceb27' \
  -d '{
	"userToken" : "8543c63333423b0d68af2f50195eb6da6402342b"
}'
```
9. launch new service version
```bash
  helm install helm/k8spoc-1.2.1-SNAPSHOT.tgz -n k8spoc-v2
```
10. Configure shifting traffic with new version
```bash
  kubectl apply -f istio/traffic-shifting.yaml
```
update the virtual service causes 50% traffic is routed to k8spoc (v1) and the 50% traffic is routed to the v2 of the service

11. What's next ...
* Controlling third party request [Istio Egress](https://istio.io/docs/tasks/traffic-management/egress/)
* Implements service security [Istio Security](https://istio.io/docs/tasks/security/)
* Service monitoring [Istio Telemetry](https://istio.io/docs/tasks/telemetry/)
