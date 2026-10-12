# CI/CD Pipeline: Flask on AWS ECS

A Flask app that returns `Hello from CI/CD Pipeline!`, packaged with Docker, provisioned on AWS with Terraform, and deployed automatically by GitHub Actions.

## Architecture

```
git push → GitHub Actions → test → build image → push to ECR → update ECS → smoke test
Visitor → Application Load Balancer (port 80) → ECS Fargate task (port 3000) → Flask
```

## Repository structure

| Path | Purpose |
|---|---|
| `app.py` | Flask application |
| `test_app.py` | pytest test used by the pipeline |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container image recipe |
| `infra/` | Terraform: VPC, subnets, Internet Gateway, security groups, ECR, ECS, ALB |
| `.github/workflows/ci-cd.yml` | CI/CD pipeline |

## Prerequisites

- Ubuntu (or any Linux/macOS), Python 3.12, Docker, Git
- AWS account and an IAM user with an access key
- AWS CLI v2 and Terraform >= 1.5
- A GitHub account

## 1. Run the app locally

```bash
git clone https://github.com/Olawale-adebayo/cicd-app.git
cd cicd-app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

In another terminal:

```bash
curl http://localhost:3000
```

Expected: `Hello from CI/CD Pipeline!`

## 2. Run the tests

```bash
pip install pytest
pytest -v
```

Expected: `1 passed`

## 3. Build and run with Docker

```bash
docker build -t cicd-app .
docker run -d -p 3000:3000 --name cicd-app-local cicd-app
curl http://localhost:3000
docker rm -f cicd-app-local
```

## 4. Configure AWS

```bash
aws configure
aws sts get-caller-identity
```

## 5. Provision infrastructure with Terraform

```bash
cd infra
terraform init
terraform validate
terraform plan
terraform apply
```

Type `yes` when prompted. Expected: `Apply complete! Resources: 19 added`.

Get the load balancer address:

```bash
terraform output alb_dns_name
```

## 6. Configure the GitHub Actions pipeline

Add two repository secrets (Settings → Secrets and variables → Actions), or use the GitHub CLI:

```bash
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
```

The workflow in `.github/workflows/ci-cd.yml` runs on every push to `main`:

1. **Test and build:** installs dependencies, runs pytest, builds the Docker image.
2. **Deploy to AWS:** logs in to AWS and ECR, pushes the image, updates the ECS service, and smoke-tests the load balancer.

## 7. Deploy

```bash
git add .
git commit -m "Deploy"
git push origin main
```

Watch the run in the repository's **Actions** tab.

## 8. Verify

```bash
curl http://$(terraform -chdir=infra output -raw alb_dns_name)
```

Expected: `Hello from CI/CD Pipeline!`

In the AWS Console, check ECR (image present), ECS (service running 1/1 tasks) and EC2 → Target Groups (target healthy).

## 9. Clean up

```bash
cd infra
terraform destroy
```

Type `yes`. This removes all AWS resources and stops billing.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Credentials could not be loaded` in the pipeline | Check the secret names are exactly `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` |
| `RepositoryNotFoundException` / `ClusterNotFoundException` | Run `terraform apply` in `infra/` first |
| `503` from the load balancer | Wait 2 to 3 minutes for the task to become healthy |
| `port is already allocated` | Stop whatever is using port 3000 |