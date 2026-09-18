# GitHub Actions OIDC → Lightsail (push + deploy only)

## Trust policy (IAM role for GitHub)

Create role `strivepay-github-lightsail` with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:Payblendio/strivepay-api:*",
            "repo:Payblendio/strivepay-consumer-web:*",
            "repo:Payblendio/strivepay-admin-web:*",
            "repo:Payblendio/strivepay-infra:*"
          ]
        }
      }
    }
  ]
}
```

## Permissions policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LightsailContainers",
      "Effect": "Allow",
      "Action": [
        "lightsail:GetContainerServices",
        "lightsail:GetContainerServiceDeployments",
        "lightsail:GetContainerImages",
        "lightsail:CreateContainerServiceDeployment",
        "lightsail:RegisterContainerImage",
        "lightsail:DeleteContainerImage",
        "lightsail:PushContainerImage",
        "lightsail:GetContainerAPIMetadata",
        "lightsail:GetBuckets",
        "lightsail:PutBucketObject",
        "lightsail:GetBucketAccessKeys",
        "lightsail:CreateBucketAccessKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EcrPublicForPushHelper",
      "Effect": "Allow",
      "Action": [
        "ecr-public:GetAuthorizationToken",
        "sts:GetServiceBearerToken"
      ],
      "Resource": "*"
    }
  ]
}
```

## GitHub secrets (shared)

| Name | Value |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/strivepay-github-lightsail` |
| `AWS_REGION` | `eu-west-2` |

OIDC provider must exist:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list ffffffffffffffffffffffffffffffffffffffff
```
