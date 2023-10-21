# ControlPlane

[![Maintainability](https://api.codeclimate.com/v1/badges/5940b79db426301ef085/maintainability)](https://codeclimate.com/repos/6533a89e41dd881b4bf91de7/maintainability)

## Introduction

Welcome to the Control-Plane! This is a centralized management layer designed to facilitate seamless interactions between multiple services. Built with Rails 7, Control-Plane aims to serve as the orchestrator for various microservices, manage stateful databases, and handle other business logic & operations.

### Technology Stack 
- **Backend** : Rails 7 
- **Database** : PostgreSQL, Redis 
- **Containerization** : Docker 
- **CI/CD** : GitHub Actions

## Setup and Installation

### System Requirements
1. Ensure Docker and Docker Compose are installed on your machine. These are essential for setting up the development environment.

### Get the Code

Firstly, clone the `ControlPlane` repository onto your local machine using the following command:

```bash
git clone git@github.com:Multiwoven/control-plane.git
```

After the repository is cloned, navigate to its root directory:

```bash
cd control-plane/
```

### Environment Variables Setup 
 
1. Create a new file named `.env` under control-plane/ directory.

On Unix/Linux systems, you can run:

```bash
touch .env
```

```env
RAILS_ENV=development
RAILS_MASTER_KEY=your_secret_key_here
AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_REGION=your_aws_region_here
```

Save and close the file.

The environment variables set in the `.env` file will be automatically picked up by Docker Compose when you run the `docker-compose` commands in the subsequent steps.

### Setting Up Services Using Docker

Using Docker, the setup is streamlined and straightforward:

#### Step 1: Build Docker Images

Execute the following command to build the Docker image for all services:

```bash
docker-compose build
```

#### Step 2: Start Services

Run the following command to start all services:

```bash
docker-compose up
```

This command will use the configurations set in the `docker-compose.yml` file to start all services, ensuring they interact as specified.