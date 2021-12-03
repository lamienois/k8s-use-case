#!/bin/sh

DATABASE_FILES="wordpress/database/manifests/"
WORDPRESS_FILES="wordpress/web/manifests/"
APP_2048_FILES="2048/manifests/"
INGRESS_FILES="ingress/manifests/"
WORDPRESS_NS="wordpress"
INGRESS_NS="ingress-nginx"
APP_2048_NS="app-2048"
NGINX_CONTROLLER_SVC="ingress-nginx-controller"

CREATE_NS () {
    for NS in $*
    do 
        [[ -z $(kubectl get ns $NS --ignore-not-found) ]] && kubectl create ns $NS || echo "$NS already created!"
    done
}

DELETE_NS () {
    for NS in $*
    do 
        [[ ! -z $(kubectl get ns $NS --ignore-not-found) ]] && kubectl delete ns $NS || echo "$NS does not exist!"
    done
}

ARG=$1

case $ARG in
    create)
        # Creating wordpress and 2048 namespaces before applying configuration files
        # Ingress namespace will be automaticaly created with the ingress configuration
        CREATE_NS $APP_2048_NS $WORDPRESS_NS

        # Ingress deployment
        kubectl -n $INGRESS_NS apply -f $INGRESS_FILES

        # Get Ingress external end-point (Ip and DNS name)
        EXTERNAL_DNS=$(kubectl -n $INGRESS_NS get svc $NGINX_CONTROLLER_SVC --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        EXTERNAL_IP=$(host $EXTERNAL_DNS | awk {'print $4'})

        WP_EXTERNAL_URL="wp.${EXTERNAL_IP}.nip.io"
        2048_EXTERNAL_URL="2048.${EXTERNAL_IP}.nip.io"

        # Update template file with the external end-point public IP
        # __PUBLICNDSNAME__ is used as the value to replace within the template file
        [[ -e ${WORDPRESS_FILES}web-ingress-rule.yaml ]] && rm -rf ${WORDPRESS_FILES}web-ingress-rule.yaml && \
        sed s/__PUBLICDNSNAME__/$EXTERNAL_URL/g ${WORDPRESS_FILES}web-ingress-rule.yaml.tpl > ${WORDPRESS_FILES}web-ingress-rule.yaml || \
        sed s/__PUBLICDNSNAME__/$EXTERNAL_URL/g ${WORDPRESS_FILES}web-ingress-rule.yaml.tpl > ${WORDPRESS_FILES}web-ingress-rule.yaml
        
        [[ -e ${APP_2048_FILES_FILES}web-ingress-rule.yaml ]] && rm -rf ${APP_2048_FILES}web-ingress-rule.yaml && \
        sed s/__PUBLICDNSNAME__/$EXTERNAL_URL/g ${APP_2048_FILES}web-ingress-rule.yaml.tpl > ${APP_2048_FILES}web-ingress-rule.yaml || \
        sed s/__PUBLICDNSNAME__/$EXTERNAL_URL/g ${APP_2048_FILES}web-ingress-rule.yaml.tpl > ${APP_2048_FILES}web-ingress-rule.yaml

        # Push ingress rule 
        kubectl -n $WORDPRESS_NS apply -f ${WORDPRESS_FILES}web-ingress-rule.yaml
        kubectl -n $APP_2048_NS apply -f ${APP_2048_FILES}web-ingress-rule.yaml

        # MySQL deployment
        kubectl -n $WORDPRESS_NS apply -f $DATABASE_FILES 

        # WP deployment
        kubectl -n $WORDPRESS_NS apply -f $WORDPRESS_FILES
        
        # 2048 deployment
        kubectl -n $APP_2048_NS apply -f $APP_2048_FILES

        echo "http://$WP_EXTERNAL_URL && http://$2048_EXTERNAL_URL"
        exit 0
    ;;
    delete)
        kubectl -n $WORDPRESS_NS delete -f $WORDPRESS_FILES
        kubectl -n $WORDPRESS_NS delete -f $DATABASE_FILES
        kubectl -n $APP_2048_NS delete -f $APP_2048_FILES
        DELETE_NS $APP_2048_NS $WORDPRESS_NS
        kubectl -n $INGRESS_NS delete -f $INGRESS_FILES
        exit 0
    ;;
    *)
        echo "Usage $0 [create|delete]"
        exit 1
    ;;
esac