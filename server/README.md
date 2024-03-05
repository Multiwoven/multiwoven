<div align="center">
  <a href="https://multiwoven.com?utm_source=github" target="_blank">
    <img alt="Multiwoven Logo" src="https://framerusercontent.com/images/QI2W5kDjl2HGKnAISsV9WVxcR0I.png?scale-down-to=512" width="280"/>
  </a>
</div>

<br/>

<p align="center">
   <a href="https://github.com/Multiwoven/multiwoven"><img src="https://img.shields.io/badge/Contributions-welcome-brightgreen.svg" alt="Contributions Welcome"></a>
   <a href="https://github.com/Multiwoven/multiwoven-server/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPL-blue.svg" alt="AGPL License"></a>
  <a href="https://github.com/Multiwoven/multiwoven-server/actions/workflows/ci.yml"><img src="https://github.com/Multiwoven/multiwoven-server/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/Multiwoven/multiwoven-server/actions/workflows/docker-build.yml"><img src="https://github.com/Multiwoven/multiwoven-server/actions/workflows/docker-build.yml/badge.svg" alt="Docker Build"></a><br />
  <a href="https://codeclimate.com/repos/657bb07835753500df74ff6a/maintainability"><img src="https://api.codeclimate.com/v1/badges/5f5a5f94f8c86a1fb02b/maintainability" alt="Maintainability"></a>
  <a href="https://codeclimate.com/repos/657bb07835753500df74ff6a/test_coverage"><img src="https://api.codeclimate.com/v1/badges/5f5a5f94f8c86a1fb02b/test_coverage" alt="Test Coverage"></a>
</p>

<h2 align="center">The open-source Reverse ETL platform for data teams</h2>

<div align="center">Effortlessly sync customer data from the datawarehouse into your business tools.</div>

<p align="center">
    <br />
    <a href="https://docs.multiwoven.com" rel=""><strong>Explore the docs »</strong></a>
    <br />
  <br/>
  <a href="https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g">Slack</a>
    ·
    <a href="https://github.com/Multiwoven/multiwoven-server/issues/new">Report Bug</a>
    ·
    <a href="https://github.com/Multiwoven/multiwoven-server/issues/new">Request Feature</a>
    ·
    <a href="https://github.com/orgs/Multiwoven/projects/4">Roadmap</a>
</p>
  
## Multiwoven Server
**Multiwoven Server**  repository contains the backend codebase for the Multiwoven platform. It is built using Ruby on Rails and Temporal Workflow Engine. The server is responsible for handling the API requests, managing the data sync workflows, and orchestrating the data sync jobs.

## Table of Contents

- [Technology Stack](#technology-stack)
- [Local Setup](#local-setup)
- [Resources](#resources)
- [Contributing](#contributing)
- [Need Help?](#need-help)
- [License](#license)

## Technology Stack

The Multiwoven Server is built using the following technologies:

- **Ruby on Rails**: The server is built using Ruby on Rails, a popular web application framework.
- **Temporal Workflow Engine**: Temporal is an open-source, stateful, and scalable workflow orchestration platform for developers. It is used to manage the data sync workflows and orchestrate the data sync jobs.
- **PostgreSQL**: The server uses PostgreSQL as the primary database to store the application data.
- **Docker**: The server is deployed using Docker containers.

## Local Setup

To deploy the Multiwoven Server locally, follow the steps below:

1. **Clone the repository:**

```bash
git clone git@github.com:Multiwoven/multiwoven-server.git
```

2. **Go inside multiwoven-server folder:**

```bash
cd multiwoven-server
```

3. **Initialize .env file:**

```bash
mv .env.example .env
```

4. **Start the services:**

```bash
docker-compose build && docker-compose up
```

5. **Access the application:**

```bash
http://localhost:3000
```

**The default page will be the API health check page.**

For more details, check out the local [deployment guide](https://docs.multiwoven.com/guides/setup/docker-compose-dev) in the documentation.

### Resources

- [Product Documentation](https://docs.multiwoven.com)
- [API Reference](https://docs.multiwoven.com/api-reference/introduction)

## Contributing

We ❤️ contributions and feedback! Help make Multiwoven better for everyone!

Before contributing to Multiwoven, please read our [Code of Conduct](https://github.com/Multiwoven/multiwoven/blob/main/CODE_OF_CONDUCT.md) and [Contributing Guidelines](https://github.com/Multiwoven/multiwoven/blob/main/CONTRIBUTING.md). As a contributor, you are expected to adhere to these guidelines and follow the best practices.

## Need Help?

We are always here to help you. If you have any questions or need help with Multiwoven, please feel free to reach out to us on [Slack](https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g). We are open to discuss new ideas, features, and improvements.

### ⚠️ Development Status: Under Active Development

This project is under active development, As we work towards stabilizing and enhancing the project, you might encounter some bugs or incomplete features. We greatly value your contributions and patience during this phase. If you find any issues not already listed, please feel free to open a new issue with detailed information. Your feedback is crucial in helping us improve. Thank you for your support!

## License

Multiwoven Server © 2023 Multiwoven Inc. Released under the [GNU Affero General Public License v3.0](https://github.com/Multiwoven/multiwoven/blob/main/LICENSE).
