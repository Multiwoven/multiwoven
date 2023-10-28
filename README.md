# ControlPlane

[![Rails CI](https://github.com/Multiwoven/control-plane/actions/workflows/ci.yml/badge.svg)](https://github.com/Multiwoven/control-plane/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/5d2521efe20af922cdda/maintainability)](https://codeclimate.com/repos/6533b99263f9fc1066cba954/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5d2521efe20af922cdda/test_coverage)](https://codeclimate.com/repos/6533b99263f9fc1066cba954/test_coverage)

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
RAILS_MASTER_KEY=your_secret_key_here
DB_HOST=your_postgres_host
DB_USERNAME=your_postgres_username
DB_PASSWORD=your_postgres_password
```

Save and close the file.

The environment variables set in the `.env` file will be automatically picked up by Docker Compose when you run the `docker-compose` commands in the subsequent steps.

### Setting Up Services Using Docker

Using Docker, the setup is streamlined and straightforward:

#### Step 1: Build Docker Images

Execute the following command to build the Docker image for all services:

**Development:**
```bash
docker-compose build
```

#### Step 2: Start Services

Run the following command to start all services:

For running **development** build:
```bash
docker-compose up
```

This command will use the configurations set in the `docker-compose.yml` file to start all services, ensuring they interact as specified.