# MultiwovenCore

## Introduction

Welcome to the `MultiwovenCore` repository. This repository serves as a monorepo, housing all the essential components for seamless integration between data warehouses and customer engagement platforms.

## Architecture

```plaintext
                 +--------------+
                 |  Frontend UI |
                 |    (React)   |
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
```

### Core Components 

1. **Control Plane** : Developed in Rails 7, responsible for managing configurations, user access, and orchestration. [Visit control-plane repo here](https://github.com/Multiwoven/control-plane) 

2. **Data Plane** : Developed in Golang, handles data processing and interactions with data warehouses. 

3. **Frontend UI** : Developed in React, serves as the user interface. [Visit frontend-ui repo here](https://github.com/Multiwoven/frontend-ui)

## Directory Structure

```plaintext
multiwoven-core/
├── Makefile                 # Makefile
├── control-plane/           # Rails 7 API-only service
├── data-plane/              # Golang service
├── frontend-ui/             # React service
├── shared/                  # Shared code or utilities
│   ├── scripts/             # DevOps and utility scripts
│   └── docs/                # Documentation
└── docker-compose-dev.yml   # Docker Compose for local development
└── docker-compose.yml       # Docker Compose for production
```

## Development Setup

### 1. Clone the Repository

```bash
git clone git@github.com:Multiwoven/multiwoven-core.git
```


### 2. Navigate to the Project Directory

```bash
cd multiwoven-core
```


### 3. Initialize Subtrees and Dependencies

Fetch all the sub-projects as git subtrees and build necessary dependencies.

```bash
make dev-init
```

### 4. Start the Services

Start all services in development mode.

```bash
make dev-up
```

**(Optional) View Logs for Development Services**

```bash
make dev-logs
```


### Verify Your Development Setup

To confirm that the services are running as expected: 
- **Control Plane** : Open `http://localhost:3000` in your web browser. 
- **Data Plane** : Open `http://localhost:4000` in your web browser. 
- **Frontend UI** : Open `http://localhost:8080` in your web browser.

## Production Setup

### 1. Clone the Repository

```bash
git clone git@github.com:Multiwoven/multiwoven-core.git
```


### 2. Navigate to the Project Directory

```bash
cd multiwoven-core
```


### 3. Initialize Subtrees and Dependencies

Fetch all the sub-projects as git subtrees and build necessary dependencies.

```bash
make prod-init
```

### 4. Start the Services

Start all services in production mode.

```bash
make prod-up
```

**(Optional) View Logs for Production Services**

```bash
make prod-logs
```

### Verify Your Production Setup

To confirm that the services are running as expected, navigate to their respective Production URLs. 
- **Control Plane** : Production URL 
- **Data Plane** : Production URL 
- **Frontend UI** : Production URL

### Makefile Commands

Below are common `make` commands you might need: 
- `make dev-init`: Initializes development environment. 
- `make prod-init`: Initializes production environment. 
- `make dev-up`: Starts all services in development mode. 
- `make prod-up`: Starts all services in production mode. 
- `make dev-down`: Stops all services in development mode. 
- `make prod-down`: Stops all services in production mode.
- `make dev-logs`: View logs from all containers in the dev environment. 
- `make prod-logs`: View logs from all containers in the prod environment.