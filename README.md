# MultiwovenCore

## Introduction

Welcome to the `MultiwovenCore` repository. This repository hosts all the core components that power the seamless integration between data warehouses and customer engagement platforms.

## Architecture

                 +--------------+
                 |  Frontend UI  |
                 +-------+------+
                         |
                         | HTTP/REST
                         |
                 +-------v------+
                 | Control Plane|
                 |    (Rails)   |
                 +-------+------+
                         |
                         | API Calls
                         |
                 +-------v------+
                 |  Data Plane  |
                 |   (Golang)   |
                 +--------------+

The architecture is built around three core components:

1. **Control Plane** : Developed in Rails 7, it's responsible for managing configurations, user access, and orchestration.

2. **Data Plane** : Developed in Golang, this component is responsible for data processing and interaction with data warehouses. 

3. **Frontend UI** : Developed in React, this is the user interface for controlling and managing the Data Plane and Control Plane.
   
## Directory Structure

```graphql
MultiwovenCore/
├── control-plane/          # Rails 7 API-only service
├── data-plane/             # Golang service
├── frontend-ui/            # React service
├── shared/                 # Shared code or utilities
│   ├── scripts/            # DevOps and utility scripts
│   └── docs/               # Documentation
├── .gitignore              # Git ignore file
├── README.md               # Project overview and setup instructions
├── docker-compose.yml      # Docker Compose for local development
```

## Setup and Installation

### System Requirements
1. Ensure Docker and Docker Compose are installed on your machine. These are essential for setting up the development environment.

### Get the Code

Firstly, clone the `MultiwovenCore` repository onto your local machine using the following command:

```bash
git clone git@github.com:Multiwoven/multiwoven-core.git
```

After the repository is cloned, navigate to its root directory:

```bash
cd multiwoven-core/
```

### Environment Variables Setup 
 
1. Create a new file named `.env` under multiwoven-core/ directory.

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

For those using Docker, the setup is streamlined and straightforward:
#### Step 1: Build Docker Images

Execute the following command to build the Docker images for all services:

```bash
docker-compose build
```

#### Step 2: Start Services

Run the following command to start all services:

```bash
docker-compose up
```

This command will use the configurations set in the `docker-compose.yml` file to start all services, ensuring they interact as specified.

### Verify Your Setup

Once the Docker setup is complete, verify that the services are running by accessing the following URLs in your web browser: 
- **Control Plane** : Navigate to `http://localhost:3000` 
- **Data Plane** : Navigate to `http://localhost:4000` 
- **Frontend UI** : Navigate to `http://localhost:8080`

By this point, you should have all services up and running, confirming that the setup is complete.