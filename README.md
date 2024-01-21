<div align="center">
  <a href="https://multiwoven.com?utm_source=github" target="_blank">
    <img alt="Multiwoven Logo" src="https://framerusercontent.com/images/QI2W5kDjl2HGKnAISsV9WVxcR0I.png?scale-down-to=512" width="280"/>
  </a>
</div>

<br/>

<p align="center">
   <a href="https://github.com/Multiwoven/multiwoven"><img src="https://img.shields.io/badge/Contributions-welcome-brightgreen.svg" alt="Contributions Welcome"></a>
   <a href="https://github.com/Multiwoven/multiwoven/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPLv3-purple" alt="License"></a>
   <br />
   <a href="https://github.com/Multiwoven/multiwoven-server/actions/workflows/ci.yml"><img src="https://github.com/Multiwoven/multiwoven-server/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
   <a href="https://github.com/Multiwoven/multiwoven-server/actions/workflows/docker-build.yml"><img src="https://github.com/Multiwoven/multiwoven-server/actions/workflows/docker-build.yml/badge.svg" alt="Docker Build"></a>
   <a href="https://codeclimate.com/repos/657bb07835753500df74ff6a/maintainability"><img src="https://api.codeclimate.com/v1/badges/5f5a5f94f8c86a1fb02b/maintainability" alt="Maintainability"></a>
   <a href="https://codeclimate.com/repos/657bb07835753500df74ff6a/test_coverage"><img src="https://api.codeclimate.com/v1/badges/5f5a5f94f8c86a1fb02b/test_coverage" alt="Test Coverage"></a>
   <br />
   <a href="https://github.com/Multiwoven/multiwoven-integrations/actions/workflows/ci.yml">
    <img src="https://github.com/Multiwoven/multiwoven-integrations/actions/workflows/ci.yml/badge.svg" alt="CI">
   </a>
   <a href="https://codeclimate.com/repos/657d0a2a60265a2f2155ffca/maintainability">
    <img src="https://api.codeclimate.com/v1/badges/d841270f1f7a966043c1/maintainability" alt="Maintainability">
   </a>
   <a href="https://codeclimate.com/repos/657d0a2a60265a2f2155ffca/test_coverage">
      <img src="https://api.codeclimate.com/v1/badges/d841270f1f7a966043c1/test_coverage" alt="Test Coverage">
   </a>
</p>

<h2 align="center">The open-source reverse ETL platform for data teams</h2>

<div align="center">Your ultimate solution for seamless data sync from warehouse to any application.</div>

<p align="center">
    <br />
    <a href="https://docs.multiwoven.com" rel=""><strong>Explore the docs »</strong></a>
    <br />

  <br/>
    <a href="https://multiwoven.com">Website</a>
    ·
    <a href="https://roadmap.multiwoven.com">Roadmap</a>
    ·
    <a href="https://twitter.com/multiwoven">X</a>
    ·
    <a href="https://multiwoven.com">Slack Community</a>
    ·
    <a href="https://github.com/Multiwoven/multiwoven/issues/new">Report Bug</a>
    ·
    <a href="https://github.com/Multiwoven/multiwoven/issues/new">Request Feature</a>
  </p>

## 💡 Why Multiwoven?
<p>
Requiring minimal engineering effort, its intuitive interface simplifies building complex data pipelines. The platform connects to popular data warehouses, including <b>Redshift, Snowflake, Databricks, and Google BigQuery</b>. Multiwoven also facilitates the crafting of data models and enables efficient synchronization of data to various destinations. Key integrations include <b>Facebook Ads</b>, CRM systems such as <b>Salesforce</b>, email marketing tools like <b>Braze and Klaviyo</b>, and analytics services including <b>Adobe Analytics</b>, making data activation accessible for every business.
</p>

<p>⭐ Consider giving us a star! Your support helps us continue innovating and adding new, exciting features.</p>

<img alt="Multiwoven" src="https://github.com/Multiwoven/multiwoven/assets/1298480/8ed5e37e-cba4-4b74-9f70-9c2bbbc11524">

## ✨ Features
- **Sources**
Efficiently connect to a wide range of data warehouses. Multiwoven supports integrations with Redshift, Snowflake, Databricks, Google BigQuery, and more, providing a solid foundation for data extraction and management.

- **Destinations**
Deploy data to over 100+ different platforms. With seamless integrations to tools like Braze, Klaviyo, Facebook Ads, Salesforce, and more, Multiwoven ensures your data reaches its intended destination effectively.

- **Models**
Craft powerful data models using SQL, visual builders, or DBT. Multiwoven's flexible modeling options allow for precise and customized data handling, suitable for any business need.

- **Syncs**
Schedule and monitor your data pipelines with ease. Multiwoven's syncing features enable you to streamline the flow of data from sources to various destinations, ensuring timely and accurate data delivery.

<hr>

## Deploy Locally

### Requirements 
1. **Install Docker:**  Ensure Docker is installed on your machine. [Docker installation guide](https://docs.docker.com/get-docker/) 
2. **Docker Compose:**  Verify that Docker Compose is installed and available (usually included with Docker Desktop). [Docker Compose documentation](https://docs.docker.com/compose/)

### Run the App

To start using Multiwoven, execute the following commands in your terminal:

```
# Get the code
git clone git@github.com:Multiwoven/multiwoven.git

# Navigate to the multiwoven folder
cd multiwoven

# Start the application
docker-compose up
```

After running these commands, open your web browser and navigate to `http://localhost:3000` to access the Multiwoven frontend application. The Multiwoven API will be available at `http://localhost:3001`.

### Troubleshooting

If you encounter any issues during the setup, such as Docker or Git-related errors, refer to the official documentation for troubleshooting tips or reach out to the community for support.

## Self-hosted Options

Multiwoven can be deployed in a variety of environments, from fully managed cloud services to self-hosted solutions. Below is a guide to deploying Multiwoven on different platforms:

| Provider | Documentation |
|:---------|:--------------|
| **AWS EC2** | [Deployment Guide](#) |
| **AWS ECS** | [Deployment Guide](#) |
| **AWS EKS (Kubernetes)** | [Deployment Guide](#) |
| **Azure VMs** | [Deployment Guide](#) |
| **Azure AKS (Kubernetes)** | [Deployment Guide](#) |
| **Google Cloud GKE (Kubernetes)** | [Deployment Guide](#) |
| **Google Cloud Compute Engine** | [Deployment Guide](#) |
| **Digital Ocean Droplets** | [Deployment Guide](#) |
| **Digital Ocean Kubernetes** | [Deployment Guide](#) |
| **Heroku** | [Deployment Guide](#) |
| **Docker** | [Deployment Guide](#) |
| **OpenShift** | [Deployment Guide](#) |
| **Helm Charts** | [Deployment Guide](#) |

## Documentation

Explore documentation for Multiwoven at [Multiwoven Documentation](https://docs.multiwoven.com/) . 
- [Create Data Pipelines](https://docs.multiwoven.com/)
- [Data Transformation](https://docs.multiwoven.com/)
- [Explore Use Cases](https://docs.multiwoven.com/)


## Contributing

Interested in contributing to Multiwoven? Here's how you can help: 

- **Reporting Issues:**  Encounter a bug or have a suggestion? Open an issue on our [GitHub repository](https://github.com/Multiwoven/multiwoven/issues) . 

- **Submitting Pull Requests:**  Have a fix or a new feature? Submit a pull request. Check our [contributing guidelines](https://docs.multiwoven.com/docs/contributing)  for more details. 

- **Joining the Discussion:**  Share your insights and engage with the community in our [Slack channel](#).

Your contributions and feedback help make Multiwoven better for everyone!

## License
Multiwoven © 2023, Multiwoven Inc - Released under the GNU Affero General Public License v3.0.
