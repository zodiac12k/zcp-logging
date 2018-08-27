# zcp-logging

## Install elasticsearch PV Claim
1. PVC 생성

$ kubectl create -f pvc.yaml
persistentvolumeclaim "elasticsearch-data-elasticsearch-data-0" created

2. 생성한 PVC의 상태가 Bound로 되었는지 확인

$ kubectl get pvc
NAME                                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS               AGE
elasticsearch-data-elasticsearch-data-0   Bound     pvc-e6f4738b-a771-11e8-84b7-aa133192a9ef   200Gi      RWO            ibmc-block-retain-silver   8m

3. PV가 제대로 Bound되었는지 확인

$ kubectl get pv

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                                                STORAGECLASS               REASON    AGE

pvc-e6f4738b-a771-11e8-84b7-aa133192a9ef   200Gi      RWO            Retain           Bound      zcp-system/elasticsearch-data-elasticsearch-data-0   ibmc-block-retain-silver             4m


만일 logging node가 3개라면 pvc.yaml안의 pv name의 숫자를 변경해가면서 생성한다.
1. PVC 생성

$vi pvc.yaml

...

metadata:

  name: elasticsearch-data-elasticsearch-data-0 <- 0을 1로 변경

  annotations:

    volume.beta.kubernetes.io/storage-class: ibmc-block-retain-silver

..

$ kubectl create -f pvc.yaml

persistentvolumeclaim "elasticsearch-data-elasticsearch-data-1" create

$ vi pvc.yaml <- 위의 숫자를 2로 변경

$ kubectl create -f pvc.yaml
persistentvolumeclaim "elasticsearch-data-elasticsearch-data-2" created


2. 생성한 PVC의 상태가 Bound로 되었는지 확인

$ kubectl get pvc

NAME                                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS               AGE

elasticsearch-data-elasticsearch-data-0   Bound     pvc-e6f4738b-a771-11e8-84b7-aa133192a9ef   200Gi      RWO            ibmc-block-retain-silver   8m

elasticsearch-data-elasticsearch-data-1   Bound     pvc-13939589-a772-11e8-84b7-aa133192a9ef   200Gi      RWO            ibmc-block-retain-silver   7m

elasticsearch-data-elasticsearch-data-2   Bound     pvc-1961fb18-a772-11e8-84b7-aa133192a9ef   200Gi      RWO            ibmc-block-retain-silver   6m


3. PV가 제대로 Bound되었는지 확인

$ kubectl get pv

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                                                STORAGECLASS               REASON    AGE

pvc-e6f4738b-a771-11e8-84b7-aa133192a9ef   200Gi      RWO            Retain           Bound      zcp-system/elasticsearch-data-elasticsearch-data-0   ibmc-block-retain-silver             4m

pvc-13939589-a772-11e8-84b7-aa133192a9ef   200Gi      RWO            Retain           Bound      zcp-system/elasticsearch-data-elasticsearch-data-1   ibmc-block-retain-silver             3m

pvc-1961fb18-a772-11e8-84b7-aa133192a9ef   200Gi      RWO            Retain           Bound      zcp-system/elasticsearch-data-elasticsearch-data-2   ibmc-block-retain-silver             7m



## Install logging system

- 입력대상 파일들

fluent-bit/fluent-bit-ds.yaml


1. elasticsearch 설치

$ kubectl create -f elasticsearch

deployment.extensions "elasticsearch-client" created

configmap "es-configmap" created

configmap "es-curator" created

service "elasticsearch-data" created

statefulset.apps "elasticsearch-data" created

service "elasticsearch-discovery" created

deployment.extensions "elasticsearch-master" created

clusterrolebinding.rbac.authorization.k8s.io "elastic-read" created

clusterrole.rbac.authorization.k8s.io "elastic-read" created

service "elasticsearch" created


2. kibana 설치

$ kubectl create -f kibana/

configmap "kibana-config" created

deployment.extensions "kibana" created

service "kibana" created


3. fluent-bit 설치

$ kubectl create -f fluent-bit/

configmap "fluent-bit-config" created

daemonset.extensions "fluent-bit" created

clusterrolebinding.rbac.authorization.k8s.io "fluent-bit-read" created

clusterrole.rbac.authorization.k8s.io "fluent-bit-read" created


4. fluentd 설치

$ kubectl create -f fluentd/

deployment.apps "fluentd-aggregator" created

service "fluentd-aggregator" created

configmap "fluentd-config" created

clusterrolebinding.rbac.authorization.k8s.io "fluentd-read" created

clusterrole.rbac.authorization.k8s.io "fluentd-read" created

service "fluentd" created


5. 설치된 pod을 확인

$ kubectl get pod

NAME                                                  READY     STATUS    RESTARTS   AGE

elasticsearch-client-7649b9b8f5-r5h8j                 2/2       Running   0          1m

elasticsearch-data-0                                  1/1       Running   0          1m

elasticsearch-data-1                                  1/1       Running   0          1m

elasticsearch-data-2                                  1/1       Running   0          1m

elasticsearch-master-f9c6bb656-f92wk                  1/1       Running   0          1m

fluent-bit-2f2dq                                      1/1       Running   0          1m

fluent-bit-2l2dn                                      1/1       Running   0          1m

fluent-bit-4j8j2                                      1/1       Running   0          1m

fluent-bit-9556p                                      1/1       Running   0          1m

fluent-bit-kp62w                                      1/1       Running   0          1m

fluent-bit-mrwp8                                      1/1       Running   0          1m

fluent-bit-n8psk                                      1/1       Running   0          1m

fluent-bit-nmt8n                                      1/1       Running   0          1m

fluent-bit-r65kq                                      1/1       Running   0          1m

fluent-bit-sg6t4                                      1/1       Running   0          1m

fluent-bit-zf6gs                                      1/1       Running   0          1m

fluentd-aggregator-bb598fc8d-gqks5                    1/1       Running   0          1m

kibana-787d7d7d8c-2rv2w                               1/1       Running   0          1m



## logging을 위한 keycloak proxy 설치

1. Keycloak 폴더로 이동

$ cd keycloak/


2. 다른 value 파일들을 참고해서 클러스터명을 붙여서 value file 생성

$ cp values_gdi.yaml values_labs.yaml


3. 변경사항 수정

- 변경 내용

host name, authServerUrl : domain name

realPublickey : keycloak의 zcp realm에 있는 Public key

ALB ID : private 환경인 경우에만 사용. 아닐 시 주석처리

<참고> ALB ID 확인방벙

$ ic cs albs --cluster zcp-dtlabs <- cluster명

OK

ALB ID                                            Enabled   Status     Type      ALB IP           Zone
private-cr5b9db2e16f62495b9ed316eb298760c6-alb1   false     disabled   private   -                -

public-cr5b9db2e16f62495b9ed316eb298760c6-alb1    true      enabled    public    169.56.106.158   seo01


$ vi values_labs.yaml

  annotations:

    ingress.bluemix.net/ALB-ID: private-crd141bb7f5a0047f180fe05ed4b5404a5-alb1


  hosts:

    - labs-logging.cloudzcp.io

  tls:

    - secretName: cloudzcp-io-cert

      hosts:

        - labs-logging.cloudzcp.io


configmap:

  targetUrl: http://kibana:5602/

  realm: zcp

  realmPublicKey: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsdAx6CerNa1aQQK1p0dfg0w4zjW1ycq81afDMdZl80WxYRaT1Q3oa7GWDkkFhu4rkjbLOPyipujEk4ouO2deK6o4wT3enJbwo4tVXrL6unS18roOOkVctBGZSJ0WacBgrml4JRw25bnl+ibrZw+h5ooF3t7iSGCIHPSwykELQJdrJvYgSWuo4lEsFcq3QCiOh4RQhnJPLbEvAWwQvlNgnMUfI7uMMEpIW1xA1Mbp5qFGqmCN1EFmYRmtYpbfMDAnMl+xB/8sMrTKzk1euiiOb5B+7ElDv6STrX9pdiGbGN1zskxDlZ88E2L1TX0/JInghYcj4axH88tJwmt/YIrbSwIDAQAB"

  authServerUrl: https://labs-iam.cloudzcp.io/auth


4. Helm 설치

$ helm install --name zcp-sso-for-logging --namespace zcp-system -f values_labs.yaml zcp/zcp-sso

만일, 잘못 올라간 helm 지우고 싶을 때는 아래 명령어를 사용.

$ helm del --purge zcp-sso-for-logging


5. 생성된 ingress 확인

- 확인사항

HOSTS 명 : 해당 클러스터의 로깅 도메인명

ADDRESS : IP ADDR가 정상적으로 할당 


$ kubectl get ingress

NAME                    HOSTS                         ADDRESS          PORTS     AGE

zcp-sso-for-logging     labs-logging.cloudzcp.io      169.56.106.158   80, 443   8s









