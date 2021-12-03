apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-rule
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: __PUBLICDNSNAME__
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress-web
            port:
              number: 80
