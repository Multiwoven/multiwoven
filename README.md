<p align="center">
  <img src="https://res.cloudinary.com/dspflukeu/image/upload/v1714997618/AIS/multiwoven_-_logo_-_light_eewnz3.svg" alt="Multiwoven" width="228" />
</p>

<h1 align="center">Open Source Reverse ETL & Data Activation Platform</h1>

<p align="center">
Multiwoven is an open-source alternative to <b>HighTouch</b>, <b>Census</b>, and <b>RudderStack</b>. It lets you easily sync data from your warehouse to any business tool, unlocking the full potential of your data.
</p>


<p align="center">
<a href="https://github.com/Multiwoven/multiwoven/stargazers"><img src="https://img.shields.io/github/stars/Multiwoven/multiwoven?style=for-the-badge" alt="GitHub stars"></a>
<a href="https://github.com/Multiwoven/multiwoven/releases">
  <img src="https://img.shields.io/github/v/release/Multiwoven/multiwoven?display_name=release&style=for-the-badge" alt="GitHub release (latest)">
</a>
  <a href="https://github.com/Multiwoven/multiwoven/graphs/commit-activity"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/Multiwoven/multiwoven/main?style=for-the-badge"></a>
  <a href="https://github.com/Multiwoven/multiwoven/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Multiwoven/multiwoven?style=for-the-badge" alt="License"></a>
  <br />
  <a href="https://github.com/Multiwoven/multiwoven/actions/workflows/server-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven/server-ci.yml?branch=main&style=for-the-badge&label=server-build" alt="server-ci"></a>
  <a href="https://github.com/Multiwoven/multiwoven/actions/workflows/integrations-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven/integrations-ci.yml?branch=main&style=for-the-badge&label=integrations-build" alt="integrations-ci"></a>
  <a href="https://github.com/Multiwoven/multiwoven/actions/workflows/ui-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Multiwoven/multiwoven/ui-ci.yml?branch=main&style=for-the-badge&label=ui-build" alt="ui-ci"></a>
</p>

<p align="center">
  <a href="https://qlty.sh/gh/Multiwoven/projects/multiwoven">
    <img src="https://qlty.sh/badges/133d1667-dc6e-4ede-8601-3120be5f175e/maintainability.svg" alt="Maintainability" /></a>
  <a href="https://qlty.sh/gh/Multiwoven/projects/multiwoven">
    <img src="https://qlty.sh/badges/133d1667-dc6e-4ede-8601-3120be5f175e/coverage.svg" alt="Code Coverage" /></a>
  </a>
</p>

<p align="center">
    <br />
    <a href="https://docs.squared.ai/open-source/introduction" rel=""><strong>Explore the docs »</strong></a>
    <br />
  <br/>
  <a href="https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g">Slack</a>
   •
    <a href="https://aisquared.ai/enterprise">Website</a>
    •
    <a href="https://aisquared.ai/blog">Blog</a>
   •
    <a href="https://github.com/orgs/Multiwoven/projects/4">Roadmap</a>
  </p>

  <hr />

## Why Multiwoven?

Multiwoven simplifies self-hosting a secure, scalable Reverse ETL platform on your cloud infrastructure like AWS, Azure, or GCP. With one-click deployment and customizable connectors, you can easily sync data from your warehouse to business tools.

⭐ *Consider giving us a star! Your support helps us continue innovating and adding new, exciting features.*

### Connect to sources

Connect to your data sources like Databricks, Redshift, BigQuery, and more.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Sources_ttijzv.png "Sources")

### Prepare your data

Create models to transform and prepare your data for syncing.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Models_ee7as8.png "Example Title")

### Sync with destinations

Sync your data with destinations like Salesforce, HubSpot, Slack, and more.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Destinations_ebpt0n.png "Example Title")


## Table of Contents

- [Getting Started](#getting-started)
  - [Local Setup](#local-setup)
  - [Self-hosted Options](#self-hosted-options)
- [Connectors](#connectors)
  - [Sources](#sources)
  - [Destinations](#destinations)
    - [CRM](#crm)
    - [Marketing Automation](#marketing-automation)
    - [Customer Support](#customer-support)
    - [Advertising](#advertising)
    - [Collaboration](#collaboration)
    - [Analytics](#analytics)
    - [Others](#others)
- [Contributing](#contributing)
- [Need Help?](#need-help)
  - [Development Status: Under Active Development](#️-development-status-under-active-development)
- [License](#license)
- [Contributors](#contributors)

## Getting Started

Multiwoven is a monorepo that consists of three main services:

- <b>server</b> - The backend service that acts as a control plane for managing data sources, models, and syncs.

- <b>ui</b> - The frontend react application that provides a user interface to manage data sources, destinations, and confgure syncs.

- <b>integrations</b> - A Ruby Gem that provides a framework to build connectors to support a wide range of data sources and destinations.

### Local Setup

To get started with Multiwoven, you can deploy the entire stack using Docker Compose.

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

4. **Copy .env file to ui folder:**

```bash
cp .env ui/.env
```

5. **Setup git hooks:**

```bash
./git-hooks/setup-hooks.sh
```

6. **Start the services:**

```bash
docker-compose build && docker-compose up
```

UI can be accessed at the PORT 8000 :

```bash
http://localhost:8000
```

For more details, check out the local [deployment guide](https://docs.squared.ai/open-source/guides/setup/docker-compose-dev) in the documentation.

### Self-hosted Options

Multiwoven can be deployed in a variety of environments, from fully managed cloud services to self-hosted solutions. Refer to the deployment guides below to deploy Multiwoven on your preferred cloud provider.

| Provider                          | Documentation                                                               |
| :-------------------------------- | :-------------------------------------------------------------------------- |
| **Docker**                        | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/docker-compose) |
| **Helm Charts**                   | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/helm)           |
| **AWS EC2**                       | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/ec2)            |
| **AWS ECS**                       | Coming soon.                                                       |
| **AWS EKS (Kubernetes)**          | Coming soon.                                                      |
| **Azure VMs**                     | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/avm)                                                       |
| **Azure AKS (Kubernetes)**        | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/aks)            |
| **Google Cloud GKE (Kubernetes)** | Coming soon.                                                             |
| **Google Cloud Compute Engine**   | [Deployment Guide](https://docs.squared.ai/deployment-and-security/setup/gce)            |
| **Digital Ocean Droplets**        | Coming soon.                                                        |
| **Digital Ocean Kubernetes**      | Coming soon.                                                             |
| **OpenShift**                     | Coming soon.                                                             |

## Connectors

🔥 Multiwoven is rapidly expanding its list of connectors to support a wide range of data sources and destinations. Head over to the [Integrations](https://github.com/Multiwoven/multiwoven/tree/main/integrations) directory to explore the available connectors. If you don't see the connector you need, please [open an issue](https://github.com/Multiwoven/multiwoven/issues) to request it.

### Sources

- [x] [Amazon Redshift](https://docs.squared.ai/guides/sources/data-sources/redshift)
- [x] [Google BigQuery](https://docs.squared.ai/guides/sources/data-sources/bquery)
- [x] [Snowflake](https://docs.squared.ai/guides/sources/data-sources/snowflake)
- [x] [Databricks](https://docs.squared.ai/guides/sources/data-sources/databricks)
- [x] [PostgreSQL](https://docs.squared.ai/guides/sources/data-sources/postgresql)

### Destinations

#### CRM

- [x] [Salesforce](https://docs.squared.ai/guides/destinations/retl-destinations/crm/salesforce)
- [ ] Zoho CRM
- [x] [HubSpot](https://docs.squared.ai/guides/destinations/retl-destinations/crm/hubspot)

#### Marketing Automation

- [x] [Klaviyo](https://docs.squared.ai/guides/destinations/retl-destinations/marketing-automation/klaviyo)
- [ ] Braze
- [ ] Salesforce Marketing Cloud

#### Customer Support

- [x] [Zendesk](https://docs.squared.ai/guides/destinations/retl-destinations/customer-support/zendesk)
- [ ] Freshdesk
- [ ] Intercom

#### Advertising

- [ ] Google Ads
- [x] [Facebook Ads](https://docs.squared.ai/guides/destinations/retl-destinations/adtech/facebook-ads)

#### Collaboration

- [x] [Slack](https://docs.squared.ai/guides/destinations/retl-destinations/team-collaboration/slack)
- [x] [Google Sheets](https://docs.squared.ai/guides/destinations/retl-destinations/productivity-tools/google-sheets)
- [x] [Airtable](https://docs.squared.ai/guides/destinations/retl-destinations/productivity-tools/airtable)

#### Analytics

- [ ] Google Analytics
- [ ] Mixpanel
- [ ] Amplitude

#### Others

🧵...Weaving in more connectors to support a wide range of destinations.

## Contributing

We ❤️ contributions and feedback! Help make Multiwoven better for everyone!

Before contributing to Multiwoven, please read our [Code of Conduct](https://github.com/Multiwoven/multiwoven/blob/main/CODE_OF_CONDUCT.md) and [Contributing Guidelines](https://github.com/Multiwoven/multiwoven/blob/main/CONTRIBUTING.md). As a contributor, you are expected to adhere to these guidelines and follow the best practices.

## Need Help?

If you have any questions or need help with Multiwoven, please feel free to reach out to us on [Slack](https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g). We are open to discuss new ideas, features, and improvements.

### ⚠️ Development Status: Under Active Development

This project is under active development, As we work towards stabilizing the project, you might encounter some bugs or incomplete features. We greatly value your contributions and patience during this phase. Thank you for your support!

## Contributors

<a href="https://github.com/Multiwoven/multiwoven/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Multiwoven/multiwoven&max=400&columns=20" />
</a>

## License

Multiwoven is licensed under the AGPLv3 License. See the [LICENSE](https://github.com/Multiwoven/multiwoven/blob/main/LICENSE) file for details.
