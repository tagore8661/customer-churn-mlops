# Customer Churn MLOps Project - End-to-End MLOps Implementation

A complete MLOps implementation for customer churn prediction using industry-standard tools. This project demonstrates automated model training, deployment, and monitoring using FastAPI, Kubernetes, KServe, GitHub Actions, and ArgoCD.

---

## Project Overview

### Business Problem
Customer churn prediction is critical for telecom, retail, and e-commerce companies to identify customers likely to leave and take proactive retention measures. Losing customers costs businesses 5-25 times more than retaining existing ones.

### Why This Project Matters
- **Real-World Impact**: Helps businesses save millions by reducing customer turnover
- **Industry Demand**: Churn prediction is one of the most common ML use cases across industries
- **MLOps Excellence**: Demonstrates production-ready ML pipeline with best practices

### Solution Architecture
```
GitHub Repository → GitHub Actions → S3 Bucket → Argo CD → Kubernetes Cluster → KServe → Model API
```
---

##  Project Structure

```
customer-churn-mlops/
├── api.py                    # FastAPI inference server
├── train.py                  # Model training script
├── generate_data.py          # Synthetic data generation
├── requirements.txt          # Python dependencies
├── Dockerfile                # Container configuration
├── README.md                 # Project documentation
├── data/                     # Dataset directory
│   └── churn_data.csv        # Generated training data
├── models/                   # Model directory
│   └── churn_model.pkl       # Trained model
├── k8s/                      # Kubernetes manifests
│   ├── serviceaccount.yml    # S3 access configuration
│   └── inference.yml         # KServe inference service
├── argocd/                   # ArgoCD configuration
│   └── argocd-application.yml
└── .github/workflows/        # CI/CD pipelines
    └── mlops-pipeline.yml    # GitHub Actions workflow
```

---

##  Quick Start

### Prerequisites
- Python 3.11+
- Docker and Docker Compose
- Kubernetes cluster (KIND recommended)
- kubectl configured
- Helm 3.0+
- AWS account with S3 access
- GitHub account

### Initial Setup

```bash
# Clone repository
git clone https://github.com/tagore8661/customer-churn-mlops
cd customer-churn-mlops

# Switch to MLOps branch
git checkout mlops

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Generate training data
python generate_data.py
# This generates 1000 samples and stores them in data/churn_data.csv

# Train model
python train.py
# This trains the model and stores it in models/churn_model.pkl

# Start local API service
python api.py
# Visit http://localhost:8000/docs for interactive API documentation
```

---

## Data Version Control with DVC

### DVC Setup

```bash
# Install DVC
pip install dvc
pip install dvc-s3

# Initialize DVC
dvc init

# Configure remote storage
dvc remote add -d s3remote s3://customer-churn-mlops-tagore
```

### Data Versioning Workflow

```bash
# Add data to DVC
dvc add data/churn_data.csv

# Track model with DVC
dvc add models/churn_model.pkl

# Push to remote storage
dvc push

# Track metadata in Git
git add data/churn_data.csv.dvc models/churn_model.pkl.dvc .gitignore
git commit -m "Add dataset and model version control"
git push
```

### DVC Benefits
- **Version Control**: Track dataset and model changes
- **Remote Storage**: Large files stored efficiently in S3
- **Team Collaboration**: Consistent data versions across team
- **Metadata Tracking**: Checksums and file information

---

## Model Deployment with KServe

### Kubernetes Cluster Setup

```bash
# Create KIND cluster
kind create cluster --name=churn-model-cluster

# Install Cert Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# Verify
kubectl get pods -n cert-manager

# Create KServe Namespace
kubectl create namespace kserve

# Install KServe CRDs
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd \
  --version v0.16.0 \
  -n kserve \
  --wait

# Install KServe Controller
helm install kserve oci://ghcr.io/kserve/charts/kserve \
  --version v0.16.0 \
  -n kserve \
  --set kserve.controller.deploymentMode=RawDeployment \
  --wait

# Verify
kubectl get pods -n kserve
```

### Service Account Configuration

**Why Service Account is Needed**: We can't deploy the model from the S3 bucket even if we write the `inference.yml` file, because our S3 bucket is private. That's why we will create the `serviceaccount.yml` file in k8s and grant access to the S3 bucket using AWS credentials. Within the serviceaccount, we will grant the S3-related permissions.

```bash
# Apply service account configuration
kubectl apply -f k8s/serviceaccount.yml

# Verify service account creation
kubectl get sa -n churn
```

### KServe Inference Service

**Important Note**: DVC stores files in a hidden hash format (files/md5/...) that KServe cannot use directly, so we must copy the model to a normal S3 path like `s3://.../models/churn_model.pkl` for serving. This separates versioning (DVC) from serving (KServe).

```bash
# Pull model from DVC storage
dvc pull models/churn_model.pkl

# Copy model to serving path
aws s3 cp models/churn_model.pkl s3://customer-churn-mlops-tagore/models/churn_model.pkl

# Deploy inference service
kubectl apply -f k8s/inference.yml

# Verify deployment
kubectl get pods -n churn -w
kubectl get svc -n churn
```

### Port Forward Service

```bash
kubectl port-forward -n churn svc/churn-predictor-predictor 8081:80 --address 0.0.0.0
```

### Test Deployed Model

Open a new terminal and test the deployed model:

```bash
curl -X POST http://localhost:8081/v1/models/churn-predictor:predict \
-H "Content-Type: application/json" \
-d '{
  "instances": [
    [70, 60, 79.99, 1920.00, 3]
  ]
}'
```

**Expected Output:**
```json
{
  "predictions": [0]
}
```

---

## CI/CD Pipeline with GitHub Actions

### GitHub Secrets Setup

**Steps to Add Secrets:**

1. Go to your GitHub repository
2. Click **Settings** tab → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter name: `AWS_ACCESS_KEY_ID` and your AWS access key
5. Click **Add secret**
6. Repeat for `AWS_SECRET_ACCESS_KEY` with your AWS secret key

**Required Secrets:**
- **AWS_ACCESS_KEY_ID**: Your AWS access key ID
- **AWS_SECRET_ACCESS_KEY**: Your AWS secret access key
- **GITHUB_TOKEN**: Default GitHub token (automatically available)

### Pipeline Workflow

The `.github/workflows/mlops-pipeline.yml` automatically triggers when you push changes to the `mlops` branch:

1. **Generate Dataset**: Creates synthetic customer data
2. **Train Model**: Trains RandomForest classifier
3. **Push to S3**: Uploads model to S3 bucket
4. **Update Config**: Updates `k8s/inference.yml` with new model path
5. **Commit Changes**: Pushes updated configuration back to repository

**Trigger Pipeline:**
```bash
git add .
git commit -m "Update model or configuration"
git push origin mlops
```

---

## GitOps with Argo CD

### Argo CD Installation

```bash
# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verify
kubectl get pods -n argocd

# Access Argo CD UI
kubectl port-forward svc/argocd-server 8080:80 -n argocd --address 0.0.0.0
# Visit "http://localhost:8080"

# Get UserID and Password
kubectl get secrets -n argocd
# We will see `argocd-initial-admin-secret`

# To Read the Secret
kubectl edit secrets/argocd-initial-admin-secret -n argocd

# Decode the Encoded Base64 Password
echo <PASSWORD> | base64 --decode
```

### ArgoCD AWS Secrets Configuration

**Why we need to edit secrets**: In our GitHub repo's `serviceaccount.yml` file, we didn't pass actual AWS credentials (they were placeholders `<ACCESS_KEY_ID>`). Without real credentials, KServe cannot access the private S3 bucket, causing CrashLoopBackOff errors.

```bash
# Edit secrets locally (for development/demo)
kubectl edit secret s3-secret -n churn
# Replace placeholder values with your actual AWS credentials
# This opens a text editor - save and close after making changes
```

### Manual ArgoCD Application Setup

**UI-Based Application Creation:**

1. Click on **NEW APP** in ArgoCD UI

**General Tab:**
- Application Name: `kserve`
- Project Name: `default`
- Sync Policy: Automatic - Enable Auto-Sync

**Source Tab:**
- Repo URL: `https://github.com/tagore8661/customer-churn-mlops.git`
- Revision: `mlops` # Branch Name
- Path: `k8s`

**Destination Tab:**
- Cluster URL: `https://kubernetes.default.svc` # Same Cluster
- Namespace: `churn`

Click **CREATE**

### Verify ArgoCD Deployment

```bash
# Check if pods are running successfully
kubectl get pods -n churn

# Check services to get the correct service name
kubectl get svc -n churn

# Port Forward to Access the Model
# Replace <POD_NAME> with the actual pod name from 'kubectl get pods'
kubectl port-forward svc/<POD_NAME> 8082:80 --address 0.0.0.0 -n churn
```

### Test ArgoCD-Deployed Model

```bash
curl -X POST http://localhost:8082/v1/models/churn-predictor:predict \
-H "Content-Type: application/json" \
-d '{
  "instances": [
    [70, 60, 79.99, 1920.00, 3]
  ]
}'
```

**Expected Output:**
```json
{
  "predictions": [0]
}
```

---

##  Complete GitOps Workflow

1. **Code Change**: Developer pushes changes to `mlops` branch
2. **GitHub Actions**: Automatically triggers CI/CD pipeline
3. **Model Training**: New model trained and evaluated
4. **S3 Upload**: Model uploaded to S3 bucket
5. **Config Update**: Inference service configuration updated
6. **Argo CD**: Detects changes in `k8s/` directory
7. **Auto Deployment**: Updates Kubernetes cluster automatically
8. **Model Serving**: New model version becomes available via API
