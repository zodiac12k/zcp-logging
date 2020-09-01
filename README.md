# zcp-logging

## Logging Component 

| Component        | Version           | Image  | etc |
| ------------- |-------------|-----|----|
|Elasticsearch| 6.3.1 |docker.elastic.co/elasticsearch/elasticsearch:6.3.1
|Kibana|  6.3.1 |docker.elastic.co/kibana/kibana:6.3.1
|Elasticsearch-curator|  5.5.4  |quay.io/pires/docker-elasticsearch-curator:5.5.4
|Fluent-bit| 0.14.9 |fluent/fluent-bit:0.14.9
|FluentD| 1.2.5 |fluent/fluentd:v1.2.5-debian | Add plugins
|Keycloak proxy| 3.4.2  |jboss/keycloak-proxy:3.4.2.Final

## Helm list
```
NAME                 	REVISION	UPDATED                 	STATUS  	CHART                      	APP VERSION	NAMESPACE
es-curator           	1       	Wed Aug 12 21:38:06 2020	DEPLOYED	elasticsearch-curator-1.5.0	5.5.4      	zcp-system
zcp-sso-for-logging  	1       	Fri Aug 14 14:26:39 2020	DEPLOYED	zcp-sso-1.0.1              	3.4.2.Final	zcp-system
```

## 사전 준비
### Helm client 설치 
설치는 각자 알아서 할 것
```shell script
$ helm init --client-only

# Repository 추가
$ helm repo add zcp https://raw.githubusercontent.com/cnpst/charts/master/docs
```

### Clone this project into desktop
```shell script
$ git clone https://github.com/cnpst/zcp-logging.git
```
설치 파일 디렉토리로 이동한다.
```shell script
$ cd zcp-logging
```

## Install elastisearch, fluentbit, fluentd, kibana with kustomize

kustomize 를 이용하여 EFK 를 설치합니다.

### for IKS elasticsearch cluster

Logging 노드가 3대인 경우

```shell script
$ kubectl create -k providers/iks
```

### for IKS elasticsearch single node

Logging 노드가 1대인 경우

```shell script
$ kubectl create -k providers/iks-single
```

### for EKS elasticsearch cluster

Logging 노드가 3대인 경우

```shell script
$ kubectl create -k providers/eks
```

### for EKS elasticsearch single node

Logging 노드가 1대인 경우

```shell script
$ kubectl create -k providers/eks-single
```

### for AKS elasticsearch cluster

Logging 노드가 3대인 경우

```shell script
$ kubectl create -k providers/aks
```

### for AKS elasticsearch single node

Logging 노드가 1대인 경우

```shell script
$ kubectl create -k providers/aks-single
```

## Install keycloak proxy (SSO) with helm

* script variables 변경
```shell script
# for IKS
$ vi keycloak-proxy/install_iks.sh
# variables
TARGET_NAMESPACE=zcp-system
KEYCLOAK_PROXY_INGRESS_HOSTS=iks-dev-logging.cloudzcp.io
KEYCLOAK_PROXY_INGRESS_CONTROLLER=private-**-alb1
REALM_PUBLIC_KEY=
AUTH_SERVER_URL=https://iks-dev-iam.cloudzcp.io/auth

# for EKS
$ vi keycloak-proxy/install_eks.sh
# variables
TARGET_NAMESPACE=zcp-system
KEYCLOAK_PROXY_INGRESS_HOSTS=eks-dev-logging.cloudzcp.io
KEYCLOAK_PROXY_INGRESS_CONTROLLER=private-nginx
REALM_PUBLIC_KEY=
AUTH_SERVER_URL=https://eks-dev-iam.cloudzcp.io/auth

# for AKS
$ vi keycloak-proxy/install_aks.sh
# variables
TARGET_NAMESPACE=zcp-system
KEYCLOAK_PROXY_INGRESS_HOSTS=aks-dev-logging.cloudzcp.io
KEYCLOAK_PROXY_INGRESS_CONTROLLER=private-nginx
REALM_PUBLIC_KEY=
AUTH_SERVER_URL=https://aks-dev-iam.cloudzcp.io/auth
```

> Public Key 확인 방법
> 1. keycloak login
> 2. ZCP Realm 선택
> 3. Realm Settings > Keys tab 선택
> 4. RSA 행의 Public key 버튼 클릭 후 값 복사
> ![](./img/2019-01-31-15-33-15.png)

> secret 확인 방법
> 1. keycloak login
> 2. ZCP Realm 선택
> 3. Clients 메뉴 선택
> 4. Logging > Credentials 선택
> 5. Secret 값 복사
> ![](./img/2019-01-31-15-37-09.png)

* 설치 스크립트 실행
```shell script
# for IKS
$ keycloak-proxy/install_iks.sh

# for EKS
$ keycloak-proxy/install_eks.sh

# for AKS
$ keycloak-proxy/install_aks.sh
```

## Install elasticsearch-curator with helm

오래된 Index를 삭제하기 위하여 curator 를 설치

```shell script
$ helm install stable/elasticsearch-curator --version 1.5.0 -n es-curator -f elasticsearch-curator/values.yaml --namespace=zcp-system
```
>
> *********** <참고> 잘못 올라간 helm 지우고 싶을 때는 아래 명령어를 사용. **************
>
```shell script
$ helm del --purge zcp-sso-for-logging
```

* 생성된 ingress 확인
> 확인사항
> * HOSTS 명 : 해당 클러스터의 로깅 도메인명  
> * ADDRESS : IP ADDR가 정상적으로 할당 

```shell script
$ kubectl get ingress
NAME                    HOSTS                         ADDRESS          PORTS     AGE
zcp-sso-for-logging     labs-logging.cloudzcp.io      XXXXXXX   80, 443   8s
```

