#!/bin/bash

# Set variables
CLUSTER_NAME="cluster-name"
ZONE="your-zone"
NAMESPACE="namespace-name"
SERVICE_NAME="service-name"
REPO_NAME="repo-name"

# Task 1: Create a GKE cluster
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --release-channel "regular" \
  --cluster-version "1.27.8-gke.1500" \
  --num-nodes "3" \
  --enable-autoscaling --min-nodes "2" --max-nodes "6"

# Task 2: Enable Managed Prometheus
gcloud container clusters update $CLUSTER_NAME --zone $ZONE --enable-managed-prometheus
kubectl create namespace $NAMESPACE

gsutil cp gs://spls/gsp510/prometheus-app.yaml .
sed -i 's|<todo>|nilebox/prometheus-example-app:latest|' prometheus-app.yaml
sed -i 's|<todo>|prometheus-test|' prometheus-app.yaml
sed -i 's|<todo>|metrics|' prometheus-app.yaml
kubectl apply -f prometheus-app.yaml -n $NAMESPACE

gsutil cp gs://spls/gsp510/pod-monitoring.yaml .
sed -i 's|<todo>|prometheus-test|' pod-monitoring.yaml
sed -i 's|<todo>|prometheus-test|' pod-monitoring.yaml
sed -i 's|<todo>|prometheus-test|' pod-monitoring.yaml
sed -i 's|<todo>|30s|' pod-monitoring.yaml
kubectl apply -f pod-monitoring.yaml -n $NAMESPACE

# Task 3: Deploy an application onto the GKE cluster
gsutil cp -r gs://spls/gsp510/hello-app/ .
kubectl apply -f hello-app/manifests/helloweb-deployment.yaml -n $NAMESPACE

# Task 4: Create a logs-based metric and alerting policy
# Note: This part involves using the GCP Console for creating the logs-based metric and alerting policy manually.

# Task 5: Update and re-deploy your app
sed -i 's|<todo>|us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0|' hello-app/manifests/helloweb-deployment.yaml
kubectl delete deployment helloweb -n $NAMESPACE
kubectl apply -f hello-app/manifests/helloweb-deployment.yaml -n $NAMESPACE

# Task 6: Containerize your code and deploy it onto the cluster
sed -i 's|Version: 1.0.0|Version: 2.0.0|' hello-app/main.go
docker build -t us-docker.pkg.dev/$REPO_NAME/hello-app:v2 hello-app/
docker push us-docker.pkg.dev/$REPO_NAME/hello-app:v2

sed -i 's|us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0|us-docker.pkg.dev/'$REPO_NAME'/hello-app:v2|' hello-app/manifests/helloweb-deployment.yaml
kubectl apply -f hello-app/manifests/helloweb-deployment.yaml -n $NAMESPACE

kubectl expose deployment helloweb --type=LoadBalancer --name=$SERVICE_NAME --port=8080 --target-port=8080 -n $NAMESPACE

# Get the external IP of the service
SERVICE_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Navigate to http://$SERVICE_IP to see the application"
