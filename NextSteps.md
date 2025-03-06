1) Install external secrets tool 

kubectl apply -f https://github.com/external-secrets/external-secrets/releases/latest/download/external-secrets.yaml

2) Create aws-secret-store.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-central-1
      auth:
        jwt:
          serviceAccountRef:
            name: django-secrets-sa

3) Create django-secrets-sa.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: django-secrets-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/<YOUR_IAM_ROLE_NAME>

4) django-external-secret.yaml

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: django-external-secret
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: django-secret
    creationPolicy: Owner
  data:
    - secretKey: SECRET_KEY
      remoteRef:
        key: prod/djangoApp/Postgres
        property: SECRET_KEY
    - secretKey: POSTGRES_USER
      remoteRef:
        key: prod/djangoApp/Postgres
        property: POSTGRES_USER
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: prod/djangoApp/Postgres
        property: POSTGRES_PASSWORD


