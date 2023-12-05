# Multiwoven Server

## Introduction

Welcome to the "multiwoven-server" repository!  This repository is developed using Rails 7, positioning itself as a central orchestrator. It is responsible for managing databases that require consistent state, as well as overseeing various business logic and operational tasks.

### Technology Stack 
- **Backend** : Rails 7 
- **Database** : PostgreSQL, Redis 
- **Containerization** : Docker 
- **CI/CD** : GitHub Actions

## Setup and Installation

### System Requirements
1. Ensure Docker and Docker Compose are installed on your machine. These are essential for setting up the development environment.

### Get the Code

Firstly, clone the `MultiwovenServer` repository onto your local machine using the following command:

```bash
git clone git@github.com:Multiwoven/multiwoven-server.git
```

After the repository is cloned, navigate to its root directory:

```bash
cd multiwoven-server/
```

### Environment Variables Setup 
 
1. Create a new file named `.env` under multiwoven-server/ directory.

On Unix/Linux systems, you can run:

```bash
touch .env
```

```env
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