kubectl create -f 2es-client-deploy.yaml
kubectl create -f es-config.yaml
kubectl create -f es-curator.yaml
kubectl create -f es-data-service.yaml
kubectl create -f 2es-data-statefulset.yaml
kubectl create -f es-discovery-service.yaml
kubectl create -f 2es-master-deploy.yaml
kubectl create -f es-service.yaml
