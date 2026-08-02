# StrideLux Terraform

Declarative IaC for the full StrideLux stack in `us-east-1` (account 254566860404): S3 + CloudFront (OAC, REST endpoint), Cognito, HTTP API Gateway with JWT authorizer and 34 routes, 5 DynamoDB tables, 7 Lambdas, IAM, Route 53, SES/DKIM, SSM, CloudWatch.

## Layout

Matches the requested structure: `main.tf`, `variables.tf`, `outputs.tf`, plus one file per service. `lambda-placeholder/` holds a stub used only at first create.

## Bootstrap (once)

The S3 backend expects a state bucket and lock table that Terraform can't create for itself:

```bash
aws s3 mb s3://stridelux-terraform-state --region us-east-1
aws dynamodb create-table --table-name stridelux-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

## Usage
# Create the state bucket (PowerShell):
aws s3api create-bucket --bucket stridelux-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket stridelux-terraform-state --versioning-configuration Status=Enabled

```bash
terraform init
terraform plan \
  -var="stripe_secret_key=sk_..." \
  -var="stripe_webhook_secret=whsec_..."
terraform apply
```

Prefer a `terraform.tfvars` (gitignored) or `TF_VAR_stripe_secret_key` env vars over CLI flags so keys don't land in shell history.

## Lambda code ownership

Terraform creates each function with a placeholder ZIP and then ignores `filename` and `source_code_hash` (`lifecycle { ignore_changes = [...] }`). GitHub Actions remains the sole deployer of function code; Terraform manages configuration (runtime, role, timeout, env vars) only. After first apply, push real packages once via the pipeline or `aws lambda update-function-code`.

## Adopting the live environment (import, don't recreate)

Since everything already exists, import rather than apply-from-scratch to avoid name collisions:

```bash
terraform import aws_s3_bucket.frontend stridelux-frontend
terraform import aws_cloudfront_distribution.frontend <DISTRIBUTION_ID>
terraform import aws_cognito_user_pool.main <USER_POOL_ID>
terraform import aws_cognito_user_pool_client.web <USER_POOL_ID>/<CLIENT_ID>
terraform import 'aws_dynamodb_table.products' stridelux-products
# ... repeat per resource; `terraform plan` after each batch to confirm zero drift
```

Notes for import mode:
- The ACM cert is modeled as a managed resource (`aws_acm_certificate.domain` in `route53.tf`) with validation records generated from `domain_validation_options`. Import the existing cert by ARN so it isn't reissued.
- Do not import the zone's NS/SOA records; they're intentionally unmanaged.
- Cognito standard-attribute `schema` blocks force replacement if they differ from the live pool; verify with `plan` before applying anything to the imported pool.

## Deliberate deviations from live (both flagged in the source)

- CloudWatch log retention set to 30 days (live: never expire) — set `log_retention_days` accordingly if you want exact parity.
- Stripe secrets are also written to SSM Parameter Store as SecureStrings (the "nice to have"); Lambda env vars still carry the values as in the live setup.
- An SPF TXT record is included but commented out in `route53.tf` — recommended, but doesn't exist today.
- DMARC remains `p=none` to match live; tighten to `p=quarantine`/`p=reject` once alignment is stable.
