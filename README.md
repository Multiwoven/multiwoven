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

