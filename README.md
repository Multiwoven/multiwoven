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
MultiwovenCore/
├── control-plane/          # Rails 7 API-only service
├── data-plane/             # Golang service
├── frontend-ui/            # React service
├── shared/                 # Shared code or utilities
│   ├── scripts/            # DevOps and utility scripts
│   └── docs/               # Documentation
├── .gitignore              # Git ignore file
├── README.md               # Project overview and setup instructions
├── docker-compose-dev.yml  # Docker Compose for local development
├── docker-compose-prod.yml # Docker Compose for production
```


## Development Setup 
1. **Clone the Repository** 

```bash
git clone https://github.com/Multiwoven/MultiwovenCore.git
``` 
2. **Navigate to the Project Directory** 

```bash
cd MultiwovenCore
``` 
3. **Start the Services** 

```bash
docker-compose -f docker-compose-dev.yml up
```
### Verify Your Development Setup

Navigate to: 
- **Control Plane** : `http://localhost:3000` 
- **Data Plane** : `http://localhost:4000` 
- **Frontend UI** : `http://localhost:8080`
## Production Setup 
1. **Clone the Repository** 

```bash
git clone https://github.com/Multiwoven/MultiwovenCore.git
``` 
2. **Navigate to the Project Directory** 

```bash
cd MultiwovenCore
``` 
3. **Start the Services** 

```bash
docker-compose -f docker-compose-prod.yml up
```
### Verify Your Production Setup

Navigate to: 
- **Control Plane** : Production URL 
- **Data Plane** : Production URL 
- **Frontend UI** : Production URL