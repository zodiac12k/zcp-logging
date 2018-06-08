kubectl create -f fluent-bit-configmap.yaml 
kubectl create -f fluent-bit-ds.yaml
kubectl create -f fluent-bit-role-binding.yaml
kubectl create -f fluent-bit-role.yaml
kubectl create -f fluent-bit-service-account.yaml
