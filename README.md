# DevOps Code Challenge 1 — Full AWS Deployment

## Overview

This repository contains a React frontend and an Express backend. The goal of this challenge is to deploy both applications to AWS using containerization, Infrastructure as Code, and an automated CI/CD pipeline.

---

## Architecture
```
Developer pushes code to GitHub
        ↓
Jenkins (EC2) detects push via webhook
        ↓
Builds Docker images for frontend and backend
        ↓
Pushes images to AWS ECR
        ↓
Triggers ECS service redeployment
        ↓
ECS Fargate pulls images and runs containers
        ↓
Users access frontend via Application Load Balancer
        ↓
Frontend calls backend via ALB on port 8080
```

### AWS Infrastructure
- **VPC** with public and private subnets across 2 availability zones
- **Internet Gateway** and **NAT Gateway** for network routing
- **Application Load Balancer** — frontend on port 80, backend on port 8080
- **ECS Cluster** running on Fargate (no EC2 instances to manage)
- **ECS Services** — frontend and backend each as separate services
- **ECR Repositories** — one for frontend image, one for backend image
- **Auto Scaling** — min 1, desired 1, max 4 tasks per service, triggered at 50% CPU
- **CloudWatch** log groups for container logs
- **IAM Roles** for ECS task execution and Jenkins EC2

---

## Live URLs

| Service | URL |
|---|---|
| Frontend | http://devops-challenge-alb-1711097062.us-east-1.elb.amazonaws.com |
| Backend | http://devops-challenge-alb-1711097062.us-east-1.elb.amazonaws.com:8080 |
| Jenkins | http://54.159.240.245:8080 |

---

## Tools Required

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0+
- [AWS CLI](https://aws.amazon.com/cli/) v2+
- [Docker](https://docs.docker.com/get-docker/)
- [Node.js](https://nodejs.org/en/download/) v16+
- [Git](https://git-scm.com/)

---

## Running Locally (Without Docker)
```bash
# Start backend first
cd backend
npm ci
npm start
# Backend available at localhost:8080

# In a new terminal, start frontend
cd frontend
npm ci
npm start
# Frontend available at localhost:3000
```

If the frontend successfully connects to the backend, the backend GUID will be displayed on the screen.

---

## Running Locally (With Docker)
```bash
# Build images
docker build -t my-frontend ./frontend
docker build -t my-backend ./backend

# Run containers
docker run -d -p 8080:8080 my-backend
docker run -d -p 3000:80 my-frontend
```

Frontend available at `localhost:3000`.

---

## Deployment Guide

### Prerequisites
1. AWS account with an IAM user configured
2. AWS CLI configured with `aws configure`
3. Terraform installed
4. An EC2 key pair created in AWS

### Step 1 — Create Terraform State Backend (One Time Only)
```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket myapp-terraform-state-YOUR_ACCOUNT_ID \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket myapp-terraform-state-YOUR_ACCOUNT_ID \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 2 — Update Terraform Backend Config
In `infrastructure/main.tf` update the bucket name with your AWS account ID.

### Step 3 — Update Variables
In `infrastructure/variables.tf` update `key_name` with your EC2 key pair name.

### Step 4 — Apply Terraform Infrastructure
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

This provisions the entire AWS infrastructure — VPC, subnets, ALB, ECS cluster, ECR repos, IAM roles, security groups, auto scaling, and the Jenkins EC2 instance.

Note the outputs after apply — you will need the ECR URLs, ALB DNS name, and Jenkins IP.

### Step 5 — Update App Config Files
Update `frontend/src/config.js` with your ALB DNS name:
```javascript
export const API_URL = 'http://YOUR_ALB_DNS:8080'
export default API_URL
```

Update `backend/config.js` with your ALB DNS name:
```javascript
module.exports = {
    CORS_ORIGIN: process.env.CORS_ORIGIN || 'http://YOUR_ALB_DNS'
}
```

### Step 6 — Set Up Jenkins
SSH into the Jenkins server:
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_JENKINS_IP
```

Install Jenkins manually (the user_data script may not complete on first boot):
```bash
sudo curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo tee /etc/yum.repos.d/jenkins.repo << EOF
[jenkins]
name=Jenkins
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
enabled=1
EOF

sudo dnf install -y jenkins --nogpgcheck
sudo usermod -aG docker jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Add swap space to prevent memory issues on t2.micro:
```bash
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
```

Access Jenkins at `http://YOUR_JENKINS_IP:8080` and complete setup:
1. Unlock with `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
2. Install suggested plugins
3. Create admin user
4. Add GitHub credentials (Personal Access Token)
5. Set Built-In Node executors to 2, usage to "Use this node as much as possible"

### Step 7 — Configure Jenkins Pipeline
1. New Item → Pipeline → name it `devops-challenge-pipeline`
2. Pipeline → Pipeline script from SCM → Git
3. Repository URL: your private GitHub repo
4. Credentials: your GitHub credentials
5. Branch: `*/main`
6. Script Path: `Jenkinsfile`
7. Build Triggers: check **GitHub hook trigger for GITScm polling**

### Step 8 — Configure GitHub Webhook
In your GitHub repo → Settings → Webhooks → Add webhook:
- Payload URL: `http://YOUR_JENKINS_IP:8080/github-webhook/`
- Content type: `application/json`
- Events: Just the push event

### Step 9 — Trigger First Deployment
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

Jenkins will automatically build, push images to ECR, and deploy to ECS.

---

## Jenkins Infrastructure (Manual Setup)

The Jenkins server infrastructure was set up manually as permitted by the challenge requirements. Here is a description of the components:

| Component | Details |
|---|---|
| **EC2 Instance** | t2.micro, Amazon Linux 2023, 30GB gp3 encrypted volume |
| **Elastic IP** | Static public IP assigned to Jenkins instance |
| **Security Group** | Port 8080 (Jenkins UI) and port 22 (SSH) open to internet |
| **IAM Role** | AdministratorAccess attached via instance profile — allows Jenkins to push to ECR, deploy to ECS, and apply Terraform without hardcoded credentials |
| **Installed Tools** | Java 17, Jenkins, Docker, AWS CLI v2, Terraform, Git |

---

## Jenkins Pipeline Stages

| Stage | Description |
|---|---|
| Checkout | Pulls latest code from GitHub |
| Build Docker Images | Builds frontend and backend Docker images |
| Authenticate to ECR | Gets ECR login token using instance IAM role |
| Tag and Push to ECR | Tags images and pushes to ECR repositories |
| Deploy to ECS | Forces new ECS deployment for both services |

---

## Configuration

**Frontend** — `frontend/src/config.js`
Defines the backend URL the frontend calls. In production this points to the ALB DNS name on port 8080.

**Backend** — `backend/config.js`
Defines the allowed CORS origin. In production this reads from the `CORS_ORIGIN` environment variable set in the ECS task definition, pointing to the ALB DNS name.

---

## Known Issues & Decisions

- **t2.micro for Jenkins** — Free tier limitation. Added 2GB swap space to prevent OOM crashes during Docker builds.
- **Single ALB with two listeners** — Frontend on port 80, backend on port 8080. Simpler than path-based routing for this application since the backend doesn't use an `/api` prefix.
- **Terraform state** — Stored remotely in S3 with DynamoDB locking so both local and Jenkins deployments share the same state.