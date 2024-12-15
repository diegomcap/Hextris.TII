# hextris-kubernetes-Terraform

## Initial Setup configuration

1. Install Minikube (which also installs kubernetes command-line tool `kubectl`)

```bash
brew install minikube 
```
- I'm in Mac Laptop but use can use [chocolatey](https://chocolatey.org/install) for windows or [WSL2](https://learn.microsoft.com/en-us/windows/wsl/)  to install on windows OS.

2. After that is done, start your cluster by running:

```bash
minikube start
```

3. Run `kubectl get svc` to see the services running in the cluster. You should get back something that looks like this:

   ![get_services](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256245/1m_bn9ufm.png)

4. The next step is to dockerize the hextris code. Since hextris is a static html page essentially, the simplest course of action is to use an nginx http server. The `Dockerfile` is pretty simple, it copies the html content from hextris to the directory nginx uses to serve static files:

```Dockerfile
FROM nginx:alpine
COPY ./code/hextris/ /usr/share/nginx/html/
```

5. To simplify the rest of the process, I decided to upload my docker image to dockerhub since using local docker images only complicates things while using minikube, because you would have to point to the docker daemon within the minikube cluster and rebuild your image (Ref: [Minikube handbook](https://minikube.sigs.k8s.io/docs/handbook/pushing/#1-pushing-directly-to-the-in-cluster-docker-daemon-docker-env)).

## Step's Overview

The way I decided to implement this exercise is in three steps:

1. Create resources using plain `.yaml` files and `kubectl`
2. Take those `.yaml` files and create a helm chart with them
3. Create a terraform configuration to create and manage all the infastructure by using the underlying helm chart.

## Step 1 (Plain kuberbetes `.yaml` files)

Because our game is pretty simple and we just use a docker image to deploy it, we won't need a ConfigMap or Secret. We simply need a Deployment that pulls our image from dockerhub and exposes port `80` from our container. Then we need a service that is of type `NodePort` so that we can access our resources externally. The kubernetes control plane allocates ports from 30000-32767 for NodePorts. I chose port 30100.

To create our resources we run the following commands:

```bash
kubectl apply -f k8s/hextris.yaml
kubectl apply -f k8s/hextris-service.yaml
```

Then if we run the following commands we should see all our resources are created:

```bash
kubectl get pods
kubectl get svc
```

![get_pods](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256246/2m_get_pods_pyxlp5.png)
![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256246/3m_get_svc_dh7k7o.png)

Our service is correctly of type `NodePort` and maps port `80:30100`. To verify that the game runs we create a tunnel with minikube to access the `hextris-service` by running `minikube service hextris-service`. Now we can access the game from our browser.

![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256246/4m_game_lpfwol.png)

## Step 2 (Creating helm chart using previous `.yaml` files)

We want to create a helm chart to essentially package the things we did in the previous step. Since this is a very simple game we are deploying the only values that are passed through to the template are values regarding the image and image tag.

By running the following command we create the chart:

```bash
helm create hextris
```

We copy the `hextris.yaml` deployment and `hextris-service.yaml` service files to the `templates/` dir within the chart. We also delete all the redundant files created.

Our folder structure looks like this:

```
hextris/
├── .helmignore   # Contains patterns to ignore when packaging Helm charts.
├── Chart.yaml    # Information about the chart
├── values.yaml   # The default values for the chart
├── charts/       # Charts that this chart depends on
└── templates/    # The template files
```

By running `helm template hextris ./hextris/` we make sure that our template renders correctly. After that to deploy our resources to our local minikube cluster we run:

```bash
helm install hextris ./hextris/
```

where we get this output:

![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256247/5m_helm_install_pfhi3i.png)

To make sure resources where created correctly we run:

```bash
helm ls
kubectl get pods
kubectl get svc
```

![helm_ls](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256247/6m_helm_ls_czesj9.png)
![get_pods](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256249/7m_get_pods_jgkwlb.png)
![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256249/8m_get_svc_mw5axf.png) 

Then create a tunnel with minikube `minikube service hextris-service`. We can access the cluster:

![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256250/9m_proof_w4d2wt.png)

## Step 3 (Creating terraform config for the infastructure)

I created a `terraform/` directory a `hextris.tf` and a `variables.tf` file.
To use our helm chart from the previous step we need to use the helm_provider from the terraform registry. As the docs state we need to supply information about the kubernetes config. We also need to supply a name and a chart location. The chart location is a directory but you could also use a remote repository.

Then we run:

```bash
terraform init
```

Then all our required provider plugins should be installed and initialized. After that if we want to see what changes need to be made to our infastructure according to our current state and our config we run:

```bash
terraform plan
```

and we should get something like this which explains if something will be replaced, changed or created in our infastructure:

![terraform_plan](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256251/10m_plan_ewmw4a.png)

Finally to create our infastructure:

```bash
terraform apply
```

and confirm by typing: `yes`

To confirm that terraform actually used our helm chart and created everything we run the following commands:

```bash
helm ls
kubectl get pods
kubectl get svc
```

![helm_ls](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256252/11m_helm_ls_qcvo99.png) 
![get_pods](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256253/12m_helm_ls_dq6uyc.png) 
![get_svc](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256254/13m_get_svc_g6prsp.png)

Now finally create a tunnel to the cluster with minikube `minikube service hextris-service`:

![proof](https://res.cloudinary.com/dlreovtdb/image/upload/v1734256255/14_m_proof_qnd3cx.png)

Now you are able to verify that everything runs correctly.