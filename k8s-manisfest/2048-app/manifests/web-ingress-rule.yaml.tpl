apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-2048-rule
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
            name: app-2048-svc
            port:
              number: 80
