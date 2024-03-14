<p align="center">
  <img src="https://res.cloudinary.com/dspflukeu/image/upload/v1706696350/Multiwoven/Logo_hrkaxj.png" alt="Multiwoven" width="228" />
</p>

<h1 align="center">Open Source Reverse ETL and Customer Data Platform (CDP)</h1>

<p align="center">
Turns any data warehouse (like Snowflake, Redshift, BigQuery, DataBricks, Postgres) into a Customer Data Platform (CDP)
</p>



<p align="center">
<a href="https://github.com/Multiwoven/multiwoven/stargazers"><img src="https://img.shields.io/github/stars/Multiwoven/multiwoven?style=for-the-badge" alt="GitHub stars"></a>
<a href="https://github.com/Multiwoven/multiwoven/releases">
  <img src="https://img.shields.io/github/v/release/Multiwoven/multiwoven?display_name=release&style=for-the-badge" alt="GitHub release (latest)">
</a>
  <a href="https://github.com/Multiwoven/multiwoven/graphs/commit-activity"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/Multiwoven/multiwoven/main?style=for-the-badge"></a>
  <a href="https://github.com/Multiwoven/multiwoven/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Multiwoven/multiwoven?style=for-the-badge" alt="License"></a>
  <br />
  <a href="https://github.com/Multiwoven/multiwoven-server/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven-server/ci.yml?style=for-the-badge&label=server-build" alt="server-ci"></a>
  <a href="https://github.com/Multiwoven/multiwoven-integrations/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven-integrations/ci.yml?style=for-the-badge&label=integrations-build" alt="integrations-ci"></a>
  <a href="https://github.com/Multiwoven/multiwoven-ui/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven-ui/ci.yml?style=for-the-badge&label=ui-build" alt="ui-ci"></a>
</p>

<p align="center">
    <br />
    <a href="https://docs.multiwoven.com" rel=""><strong>Explore the docs »</strong></a>
    <br />
  <br/>
  <a href="https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g">Slack</a>
   •
    <a href="https://multiwoven.com">Website</a>
    •
    <a href="https://blog.multiwoven.com">Blog</a>
   •
    <a href="https://github.com/orgs/Multiwoven/projects/4">Roadmap</a>
  </p>

  <hr />

## Why Multiwoven?

Multiwoven makes it easy to self-host and deploy a fully secure, scalable, and customizable CDP and Reverse ETL platform. It is built on top of open-source technologies and is designed to be easily integrated with your existing data warehouse and data lake, an open-source alternative to tools like **Hightouch**, **Census**, and **RudderStack**.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1707907478/Multiwoven/Github/image_4_lkzspc.png "Example Title")

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1707907527/Multiwoven/Github/image_6_nqkvlu.png "Example Title")

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1707907791/Multiwoven/Github/image_7_ozahsr.png "Example Title")

⭐ *Consider giving us a star! Your support helps us continue innovating and adding new, exciting features.*

## Table of Contents

- [Getting Started](#getting-started)
  - [Local Setup](#local-setup)
  - [Self-hosted Options](#self-hosted-options)
- [Connectors](#connectors)
  - [Sources](#sources)
  - [Destinations](#destinations)
- [Contributing](#contributing)
- [Need Help?](#need-help)
- [License](#license)

## Getting Started

Multiwoven repo is a monorepo that contains the following services:

- [multiwoven-server](https://github.com/Multiwoven/multiwoven-server) - The backend service that handles data extraction, modeling, and syncing.

- [multiwoven-ui](https://github.com/Multiwoven/multiwoven-ui) - The frontend service that provides a user interface for managing data sources, models, and syncs.

- [multiwoven-integrations](https://github.com/Multiwoven/multiwoven-integrations) - The connector service that provides a list of connectors to various data sources and destinations.

### Local Setup

To get started with Multiwoven, you can deploy the entire stack locally using Docker Compose.

1. **Clone the repository:**

```bash
git clone git@github.com:Multiwoven/multiwoven.git
```

2. **Go inside multiwoven folder:**

```bash
cd multiwoven
```

3. **Initialize .env file:**

```bash
mv .env.example .env
```

4. **Start the services:**

```bash
docker-compose build && docker-compose up
```

UI can be accessed at the PORT 8000 :

```bash
http://localhost:8000
```

For more details, check out the local [deployment guide](https://docs.multiwoven.com/guides/setup/docker-compose-dev) in the documentation.

### Self-hosted Options

Multiwoven can be deployed in a variety of environments, from fully managed cloud services to self-hosted solutions. Below is a guide to deploying Multiwoven on different platforms:

| Provider                          | Documentation                                                               |
| :-------------------------------- | :-------------------------------------------------------------------------- |
| **Docker**                        | [Deployment Guide](https://docs.multiwoven.com/guides/setup/docker-compose) |
| **AWS EC2**                       | [Deployment Guide](https://docs.multiwoven.com/guides/setup/ec2)            |
| **AWS ECS**                       | [Deployment Guide](#)                                                       |
| **AWS EKS (Kubernetes)**          | [Deployment Guide](#)                                                       |
| **Azure VMs**                     | Deployment Guide                                                            |
| **Azure AKS (Kubernetes)**        | Deployment Guide                                                            |
| **Google Cloud GKE (Kubernetes)** | Deployment Guide                                                            |
| **Google Cloud Compute Engine**   | [Deployment Guide](https://docs.multiwoven.com/guides/setup/gce)            |
| **Digital Ocean Droplets**        | [Deployment Guide](#)                                                       |
| **Digital Ocean Kubernetes**      | Deployment Guide                                                            |
| **OpenShift**                     | Deployment Guide                                                            |
| **Helm Charts**                   | [Deployment Guide](https://docs.multiwoven.com/guides/setup/helm)           |

## Connectors

Multiwoven is rapidly expanding its list of connectors to support a wide range of data sources and destinations. Head over to the [Multiwoven Integrations](https://github.com/Multiwoven/multiwoven-integrations) repository to contribute to the growing list of connectors.

### Sources

- [x] [Amazon Redshift](https://docs.multiwoven.com/sources/redshift)
- [x] [Google BigQuery](https://docs.multiwoven.com/sources/bquery)
- [x] [Snowflake](https://docs.multiwoven.com/sources/snowflake)
- [x] [Databricks](https://docs.multiwoven.com/sources/databricks)
- [x] [PostgreSQL](https://docs.multiwoven.com/sources/postgresql)

### Destinations

#### CRM

- [x] [Salesforce](https://docs.multiwoven.com/destinations/crm/salesforce)
- [ ] Zoho CRM
- [x] [HubSpot](https://docs.multiwoven.com/destinations/crm/hubspot)

#### Marketing Automation

- [x] [Klaviyo](https://docs.multiwoven.com/destinations/marketing-automation/klaviyo)
- [ ] Braze
- [ ] Salesforce Marketing Cloud

#### Customer Support

- [ ] Zendesk
- [ ] Freshdesk
- [ ] Intercom

#### Advertising

- [ ] Google Ads
- [x] [Facebook Ads](https://docs.multiwoven.com/destinations/adtech/facebook-ads)

#### Collaboration

- [x] [Slack](https://docs.multiwoven.com/destinations/team-collaboration/slack)
- [ ] Google Sheets

#### Analytics

- [ ] Google Analytics
- [ ] Mixpanel
- [ ] Amplitude

#### Others

🧵..Weaving in more connectors to support a wide range of destinations.

## Contributing

We ❤️ contributions and feedback! Help make Multiwoven better for everyone!

Before contributing to Multiwoven, please read our [Code of Conduct](https://github.com/Multiwoven/multiwoven/blob/main/CODE_OF_CONDUCT.md) and [Contributing Guidelines](https://github.com/Multiwoven/multiwoven/blob/main/CONTRIBUTING.md). As a contributor, you are expected to adhere to these guidelines and follow the best practices.

## Need Help?

We are always here to help you. If you have any questions or need help with Multiwoven, please feel free to reach out to us on [Slack](https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g). We are open to discuss new ideas, features, and improvements.

### ⚠️ Development Status: Under Active Development

This project is under active development, As we work towards stabilizing the project, you might encounter some bugs or incomplete features. We greatly value your contributions and patience during this phase. Thank you for your support!

## License

Multiwoven is licensed under the AGPLv3 License. See the [LICENSE](https://github.com/Multiwoven/multiwoven/blob/main/LICENSE) file for details.

## Contributors

<a href="https://github.com/Multiwoven/multiwoven/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Multiwoven/multiwoven" />
</a>
