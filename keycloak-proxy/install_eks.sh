#!/bin/bash

# variables
TARGET_NAMESPACE=zcp-system
KEYCLOAK_PROXY_INGRESS_HOSTS=eks-dev-logging.cloudzcp.io
KEYCLOAK_PROXY_INGRESS_CONTROLLER=private-nginx
REALM_PUBLIC_KEY=
AUTH_SERVER_URL=https://eks-dev-iam.cloudzcp.io/auth

helm install zcp/zcp-sso \
--name zcp-sso-for-logging \
-f values-eks.yaml \
--namespace ${TARGET_NAMESPACE} \
--set ingress.annotations."kubernetes\.io/ingress\.class"=${KEYCLOAK_PROXY_INGRESS_CONTROLLER} \
--set ingress.hosts[0]=${KEYCLOAK_PROXY_INGRESS_HOSTS} \
--set ingress.tls[0].hosts[0]=${KEYCLOAK_PROXY_INGRESS_HOSTS} \
--set configmap.realmPublicKey=${REALM_PUBLIC_KEY} \
--set configmap.authServerUrl=${AUTH_SERVER_URL} \
