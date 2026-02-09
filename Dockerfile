# Customer Churn MLOps - FastAPI Application Dockerfile
# Multi-stage container for production deployment of churn prediction API

# Use Python 3.11 slim base image for smaller size
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install system dependencies and Python packages
# build-essential needed for compiling some Python packages
RUN apt-get update && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code and model files
COPY api.py .
COPY models/ models/

# Create non-root user for security (optional but recommended)
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Expose the application port
EXPOSE 8000

# Start the FastAPI application with uvicorn server
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]