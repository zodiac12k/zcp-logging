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

## 사전 준비
### Helm client 설치 
  설치는 각자 알아서 할 것
  ```
  $ helm init --client-only

  # Repository 추가
  $ helm repo add zcp https://raw.githubusercontent.com/cnpst/charts/master/docs
  ```

### Clone this project into desktop
  ```
  $ git clone https://github.com/cnpst/zcp-logging.git
  ```
  설치 파일 디렉토리로 이동한다.
  ```
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

  * values 수정
    > 변경 할 내용
    > * ingress
    >   * hostname
    >   * ALB-ID
    > * configmap
    >   * realmPublickey
    >   * authServerUrl
    >   * secret
    
    ```
    $ vi keycloak/values.yaml
    # AKS 인 경우
    $ vi keycloak/values-aks.yaml

    ...
    ingress:
      enabled: true 
      annotations: 
        ingress.bluemix.net/redirect-to-https: "True"
        ingress.bluemix.net/ALB-ID: private-cr3d6b18b315544bcc8cdf94926c2d12c0-alb1    # ALB ID 로 수정. public 인 경우 주석처리
      path: /
      hosts:
        - logging.cloudzcp.io      # 도메인 변경
      tls:
        - secretName: cloudzcp-io-cert
          hosts:
            - logging.cloudzcp.io     # 도메인 변경
    ...
    configmap:
      targetUrl: http://kibana:5602/
      realm: zcp
      realmPublicKey: "XXXXXXXXXX"     # Keycloak 에서 Public key 확인 후 변경
      authServerUrl: https://iam.cloudzcp.io/auth   # Keycloak 도메인으로 변경
      resource: logging 
      secret: XXXXXXXXXXXXX    # Keyclock 에서 client secret 확인 후 변경
      pattern: /*	
      rolesAllowed: log-manager
    ```
    > ALB ID 확인방법
      ```sh
      $ ic cs albs --cluster zcp-dtlabs #<- cluster명
      OK
      ALB ID                                            Enabled   Status     Type      ALB IP           Zone
      private-cr5b9db2e16f62495b9ed316eb298760c6-alb1   false     disabled   private   -                -
      public-cr5b9db2e16f62495b9ed316eb298760c6-alb1    true      enabled    public    169.56.106.158   seo01
      ```

    > Public Key 확인 방법
      * keycloak login
      * ZCP Realm 선택
      * Realm Settings > Keys tab 선택
      * RSA 행의 Public key 버튼 클릭 후 값 복사
      ![](./img/2019-01-31-15-33-15.png)

    > secret 확인 방법
      * keycloak login
      * ZCP Realm 선택
      * Clients 메뉴 선택
      * Logging > Credentials 선택
      * Secret 값 복사
      ![](./img/2019-01-31-15-37-09.png)

  * Helm 설치
    ```sh
    $ helm install --name zcp-sso-for-logging --namespace zcp-system -f keycloak/values.yaml zcp/zcp-sso
    
    # AKS 인 경우
    $ helm install --name zcp-sso-for-logging --namespace zcp-system -f keycloak/values-aks.yaml zcp/zcp-sso
    ```

## Install elasticsearch-curator with helm

오래된 Index를 삭제하기 위하여 curator 를 설치

    ```shell script
    $ helm install stable/elasticsearch-curator --version 1.5.0 -n es-curator -f elasticsearch-curator/values.yaml --namespace=zcp-system

    NAME:   es-curator
    LAST DEPLOYED: Mon May 13 18:11:03 2019
    NAMESPACE: zcp-system
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1beta1/CronJob
    NAME                              SCHEDULE    SUSPEND  ACTIVE  LAST SCHEDULE  AGE
    es-curator-elasticsearch-curator  0 15 * * *  False    0       <none>         0s

    ==> v1/ConfigMap
    NAME                                     DATA  AGE
    es-curator-elasticsearch-curator-config  2     0s

    NOTES:
    A CronJob will run with schedule 0 15 * * *.

    The Jobs will not be removed automagically when deleting this Helm chart.
    To remove these jobs, run the following :

    kubectl -n zcp-system delete job -l app=elasticsearch-curator,release=es-curator
    ```
>
> *********** <참고> 잘못 올라간 helm 지우고 싶을 때는 아래 명령어를 사용. **************
>
```sh
$ helm del --purge zcp-sso-for-logging
```

  * 생성된 ingress 확인
    > 확인사항
    > * HOSTS 명 : 해당 클러스터의 로깅 도메인명  
    > * ADDRESS : IP ADDR가 정상적으로 할당 

    ```sh
    $ kubectl get ingress
    NAME                    HOSTS                         ADDRESS          PORTS     AGE
    zcp-sso-for-logging     labs-logging.cloudzcp.io      XXXXXXX   80, 443   8s
    ```

