# StrideLux — Infrastructure

Terraform Infrastructure as Code for all AWS resources powering the [StrideLux](https://strideluxstore.com) e-commerce platform. All services — DNS, CDN, compute, database, auth, email, and observability — are defined declaratively and version-controlled here.

> **Apply policy:** `terraform apply` is excluded from CI/CD. Changes are reviewed locally via `terraform plan` and applied manually to prevent unintended modifications to live infrastructure.

---

## Architecture

```
Route 53 (DNS)
    │
CloudFront (CDN + SSL/TLS)
    │                   │
S3 Bucket           API Gateway (HTTP API)
(React SPA +            │
 media assets)    Cognito JWT Authorizer
                        │
              ┌─────────┼──────────┐
              │         │          │
          Lambda     Lambda    Lambda  ...× 7
              │
          DynamoDB (5 tables)
              │
           SES (transactional email)
              │
         CloudWatch (logs, retention)
```

---

## AWS Resources

| File | Resources |
|---|---|
| `main.tf` | AWS provider, backend configuration |
| `s3.tf` | Frontend hosting bucket, media assets bucket, SSE-S3 encryption |
| `cloudfront.tf` | CDN distribution, origin access control, ACM SSL certificate |
| `route53.tf` | A / AAAA alias records for apex domain and `www` |
| `cognito.tf` | User pool, password policy, app client, user groups (Customers, Employees, Admins), post-confirmation trigger |
| `apigateway.tf` | HTTP API, stage, routes, Cognito JWT authorizer, Lambda integrations, CORS |
| `lambda.tf` | Function definitions (nodejs22.x), environment variables, lifecycle ignore for CI-managed code |
| `dynamodb.tf` | Tables: `products`, `orders`, `users`, `cart-wishlist`, `coupons` |
| `iam.tf` | Lambda execution roles scoped per function, GitHub Actions deploy user |
| `ses.tf` | Domain identity, `orders@strideluxstore.com` email identity, DKIM |
| `cloudwatch.tf` | Log groups per Lambda function with retention policies |
| `imports.tf` | Import blocks for resources provisioned before Terraform adoption |
| `outputs.tf` | CloudFront domain, API Gateway URL, Cognito IDs |
| `variables.tf` | Region, domain, Stripe keys, Cognito temp password (all sensitive values — no defaults) |

---

## Repository Structure

```
stridelux-infra/
├── terraform/
│   ├── main.tf / variables.tf / outputs.tf / imports.tf
│   ├── s3.tf / cloudfront.tf / route53.tf
│   ├── cognito.tf / apigateway.tf / lambda.tf
│   ├── dynamodb.tf / iam.tf / ses.tf / cloudwatch.tf
│   ├── lambda-placeholder/index.js   # Placeholder ZIP for initial terraform apply
│   └── .terraform.lock.hcl
├── .trivyignore                      # Documented security finding suppressions
├── .github/workflows/ci-cd.yml
├── sonar-project.properties
└── .gitignore                        # Excludes *.tfvars, *.tfstate, .terraform/
```

---

## CI/CD Pipeline

```
Push / Pull Request → main
  ├── Trivy — scans .tf files for misconfigurations and secrets
  │     ├── MEDIUM+ findings → GitHub Security tab (SARIF)
  │     └── CRITICAL findings with available fixes → pipeline blocked
  ├── SonarCloud — Terraform static analysis, quality gate
  └── Terraform Validate
        ├── terraform init -backend=false   (no state access)
        ├── terraform fmt -recursive        (auto-format)
        └── terraform validate              (syntax + internal consistency)
```

No `terraform plan` or `terraform apply` in CI. Infrastructure changes are reviewed and applied manually.

### Code Quality — Dual Analysis Strategy

**SonarCloud (cloud-hosted — active)**
Runs automatically on every pull request and push to `main`. Quality gate must pass before a PR can be merged. Free for public repositories.

**SonarQube Community Edition (self-hosted — on-demand)**
Set up on a forked repository of this codebase, backed by a self-hosted GitHub Actions runner on an EC2 instance. The EC2 is not continuously running — it is started on-demand when a targeted scan is required, then stopped. A dormant SonarQube step is included in the workflow. To activate: start the EC2, add `SONAR_HOST_URL` to the forked repo secrets, comment out the SonarCloud step, and uncomment the SonarQube step.

---

## Running Terraform Locally

```bash
cd terraform

terraform init

terraform plan \
  -var="stripe_secret_key=sk_..." \
  -var="stripe_webhook_secret=whsec_..." \
  -var="cognito_temp_password=..."

# Apply only after confirming the plan output
terraform apply \
  -var="stripe_secret_key=sk_..." \
  -var="stripe_webhook_secret=whsec_..." \
  -var="cognito_temp_password=..."
```

Or use a `terraform.tfvars` file (excluded by `.gitignore`):

```hcl
stripe_secret_key     = "sk_..."
stripe_webhook_secret = "whsec_..."
cognito_temp_password = "..."
```

---

## Security

| Control | Implementation |
|---|---|
| Misconfiguration scanning | Trivy on every push and PR |
| Secret scanning | Trivy — detects hardcoded credentials in `.tf` files |
| Static analysis | SonarCloud Terraform rules |
| State protection | `*.tfstate` excluded via `.gitignore` — never committed |
| Variable secrets | `sensitive = true`, no defaults — never in source |
| tfvars protection | `*.tfvars` excluded via `.gitignore` |
| IAM least privilege | Dedicated execution role per Lambda, scoped to specific table actions |
| SES permissions | `ses:SendEmail` on domain identity ARN + email identity ARN — no wildcard |
| S3 encryption | SSE-S3 (AES-256) on all buckets |

### Security Finding Suppressions (`.trivyignore`)

Each suppression is documented with a business justification. Summary:

| Finding | Accepted Because |
|---|---|
| `AVD-AWS-0132` S3 CMK | Public static website — SSE-S3 is sufficient; CMK adds cost with no gain |
| `AVD-AWS-0089` S3 logging | CloudFront access logs cover all user-facing traffic |
| `AVD-AWS-0090` S3 versioning | CI/CD deployment bucket — rebuilt on every push |
| `AVD-AWS-0010` CloudFront logging | Lambda + API Gateway CloudWatch covers observability |
| `AVD-AWS-0012` Geo restriction | Global storefront — geo restriction blocks legitimate users |
| `AVD-AWS-0025` DynamoDB CMK | AWS-owned encryption at rest is enabled by default |
| `AVD-AWS-0024` DynamoDB PITR | **Resolved** — PITR enabled on all 5 tables via `terraform apply` |
| `AVD-AWS-0067` Lambda X-Ray | CloudWatch Logs sufficient; X-Ray adds per-invocation cost |
| `AVD-AWS-0066` Lambda env CMK | Sensitive values in AWS SSM; env CMK would be redundant |
| `AVD-AWS-0057` IAM SES wildcard | `iam.tf` updated to scope both identity ARNs — pending `terraform apply` |

---

## Required GitHub Secrets

Required only if `terraform plan` / `terraform apply` is added to CI:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | IAM credentials |
| `TF_VAR_stripe_secret_key` | Stripe secret key |
| `TF_VAR_stripe_webhook_secret` | Stripe webhook signing secret |
| `TF_VAR_cognito_temp_password` | Temp password for admin-created Cognito users |
| `SONAR_TOKEN` | SonarCloud analysis token |

---

## Related Repositories

| Repository | Description |
|---|---|
| [stridelux-frontend](https://github.com/Joesmithessang/stridelux-frontend) | React SPA — S3 + CloudFront |
| [stridelux-backend](https://github.com/Joesmithessang/stridelux-backend) | Lambda functions — products, orders, payments, admin, cart |
