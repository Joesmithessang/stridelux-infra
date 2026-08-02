# StrideLux Infrastructure

Terraform IaC for all AWS infrastructure powering the [StrideLux](https://strideluxstore.com) e-commerce platform.

> **Note:** This repository is for infrastructure-as-code storage and validation only. `terraform apply` is run manually after reviewing the plan output. No automated apply is wired into CI/CD to prevent unintended changes to live infrastructure.

---

## AWS Resources

| File | Resources |
|---|---|
| `main.tf` | Provider configuration, Terraform backend |
| `s3.tf` | Frontend hosting bucket, media assets bucket |
| `cloudfront.tf` | CDN distribution, SSL/TLS, custom domain |
| `route53.tf` | DNS records for `strideluxstore.com` |
| `cognito.tf` | User pool, app client, user groups (customers, employees, admins) |
| `apigateway.tf` | HTTP API, routes, Cognito JWT authorizer, Lambda integrations |
| `lambda.tf` | Lambda function definitions and environment variables |
| `dynamodb.tf` | Tables: products, orders, users, cart-wishlist, coupons |
| `iam.tf` | Roles and policies for Lambda execution and GitHub Actions |
| `ses.tf` | SES email identity for transactional emails |
| `cloudwatch.tf` | Log groups and retention policies |
| `outputs.tf` | CloudFront domain, API Gateway URL, Cognito IDs |
| `variables.tf` | Input variables (region, domain, Stripe keys) |

---

## CI/CD Pipeline

Defined in [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml).

| Job | Trigger | Description |
|---|---|---|
| `security-scan` | Every push and PR | Trivy scans `.tf` files for misconfigurations and secrets. CRITICAL findings block the pipeline. |
| `code-quality` | Every push and PR | SonarCloud static analysis. SonarQube Community Edition block is included and ready to activate. |
| `terraform-validate` | Every push and PR | `terraform fmt -check` + `terraform validate`. No AWS calls, no state access — syntax only. |

### Switching from SonarCloud to SonarQube Community Edition

When your self-hosted SonarQube server is ready:
1. Add `SONAR_HOST_URL` to repo secrets (e.g. `http://your-ec2-ip:9000`)
2. Generate a `SONAR_TOKEN` from the SonarQube server
3. In `.github/workflows/ci-cd.yml`, comment out the SonarCloud step and uncomment the SonarQube step

---

## Running Terraform Locally

```bash
# Install dependencies
terraform init

# Preview changes — review carefully before applying
terraform plan -var="stripe_secret_key=sk_..." -var="stripe_webhook_secret=whsec_..."

# Apply only after confirming the plan is safe
terraform apply -var="stripe_secret_key=sk_..." -var="stripe_webhook_secret=whsec_..."
```

---

## Required GitHub Secrets

Only needed if you later enable `terraform plan` or `terraform apply` in CI:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user with infrastructure permissions |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |
| `AWS_REGION` | AWS region (e.g. `us-east-1`) |
| `TF_VAR_stripe_secret_key` | Stripe secret key (`sk_...`) |
| `TF_VAR_stripe_webhook_secret` | Stripe webhook signing secret (`whsec_...`) |
| `SONAR_TOKEN` | From sonarcloud.io (or SonarQube server when self-hosted) |

---

## Related Repositories

| Repo | Description |
|---|---|
| [stridelux-frontend](https://github.com/Joesmithessang/stridelux-frontend) | React storefront — S3 + CloudFront |
| [stridelux-backend](https://github.com/Joesmithessang/stridelux-backend) | Lambda functions — orders, products, payments, admin |
