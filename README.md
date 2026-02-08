# Customer Churn MLOps Project

A machine learning project that predicts customer churn using a Random Forest classifier. It generates synthetic customer data, trains a model, and serves predictions via FastAPI.

## Overview

This project predicts customer churn using machine learning. It generates synthetic customer data with 5 features (age, tenure, monthly charges, total charges, support calls), trains a Random Forest model, and serves predictions via a FastAPI web service. The complete pipeline includes data generation, model training with performance metrics, and a REST API for real-time churn predictions with probability scores.

## Features

- **Synthetic Data Generation**: Creates 1000 customer samples with realistic churn patterns based on monthly charges, support calls, and tenure
- **Random Forest Model**: Trains a classifier with 100 estimators and evaluates using accuracy and AUC-ROC metrics
- **FastAPI Web Service**: Provides REST API endpoints for health checks and churn predictions with probability scores
- **Interactive Documentation**: Auto-generated Swagger UI available at `/docs` for API testing
- **Model Persistence**: Saves trained model as pickle file for consistent predictions
- **Data Validation**: Uses Pydantic for automatic input validation and type checking

## Quick Start

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/tagore8661/customer-churn-mlops
   cd customer-churn-mlops
   ```

2. **Create and activate virtual environment**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Generate training data**
   ```bash
   python generate_data.py
   ```
   *This generates 1000 samples and stores them in `data/churn_data.csv`*

5. **Train the model**
   ```bash
   python train.py
   ```
   *This trains the model and stores it in `models/churn_model.pkl`*

6. **Start the API service**
   ```bash
   python api.py
   ```
   *The API will be available at `http://localhost:8000`*

## API Usage

### Interactive Documentation
Visit `http://localhost:8000/docs` for the interactive Swagger UI.

### Health Check
```bash
curl -X GET "http://localhost:8000/health"
```

### Prediction Endpoint
```bash
curl -X POST "http://localhost:8000/predict" \
-H "Content-Type: application/json" \
-d '{
  "age": 70,
  "tenure_months": 60,
  "monthly_charges": 30,
  "total_charges": 1000,
  "num_support_calls": 1
}'
```

#### Expected Output
```json
{
  "churn": 0,
  "churn_probability": 0.28
}
```