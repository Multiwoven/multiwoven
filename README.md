<p align="center">
  <img src="https://res.cloudinary.com/dspflukeu/image/upload/v1713792479/AIS/ai-squared-r-logo_kqcp5y.png" alt="Multiwoven" width="228" />
</p>

<h1 align="center">Multiwoven (EE) - AI Squared Enterprise Edition</h1>

<p align="center">
<b>Multiwoven (EE)</b> is an AI Squared enterprise edition that extends the capabilities of Multiwoven OSS with advanced features and deployment options. This codebase powers the AI squared enterprise SaaS and enterprise on-premises deployments.
</p>

<p align="center">
    <br />
    <a href="https://docs.multiwoven.com" rel=""><strong>Explore the docs »</strong></a>
    <br />
<hr />

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Getting Started](#getting-started)
  - [Local Setup](#local-setup)
- [License](#license)

## Getting Started

Multiwoven (EE) is a monorepo that consists of three main services:

- [server](https://github.com/Multiwoven/multiwoven/tree/main/server) - The backend service that acts as a control plane for managing data sources, models, and syncs.

- [ui](https://github.com/Multiwoven/multiwoven/tree/main/ui) - The frontend react application that provides a user interface to manage data sources, destinations, and confgure syncs.

- [integrations](https://github.com/Multiwoven/multiwoven/tree/main/integrations) - A Ruby Gem that provides a framework to build connectors to support a wide range of data sources and destinations.

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

4. **Start the services:**

```bash
docker-compose build && docker-compose up
```

UI can be accessed at the PORT 8000 :

```bash
http://localhost:8000
```

For more details, check out the local [deployment guide](https://docs.multiwoven.com/guides/setup/docker-compose-dev) in the documentation.

## License

Multiwoven is licensed under the AGPLv3 License. See the [LICENSE](https://github.com/Multiwoven/multiwoven/blob/main/LICENSE) file for details.
