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

## Multiwoven UI

**Multiwoven UI** repository contains the frontend codebase for the Multiwoven platform. It is built using React and Chakra UI. The frontend is responsible for managing the sources, destinations, models, and syncs.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
- [Contributing](#contributing)
- [Need Help?](#need-help)
- [License](#license)

## Prerequisites

You will need the following things properly installed on your computer.

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) (with npm, recommended node version - 18.17.0)

## Local Setup

To deploy the Multiwoven UI locally, follow the steps below:

1. **Clone the repository:**

```bash
git clone git@github.com:Multiwoven/multiwoven-ui.git
```

2. **Go inside multiwoven-ui folder:**

```bash
cd multiwoven-ui
```

3. **Install the dependencies:**

```bash
npm i
```

4. **Initialize .env file:**

```bash
mv .env.example .env
```

4. **Start the services:**

```bash
npm run dev
```

5. **Access the application:**

```bash
http://localhost:8000
```

Note: In the env, the base URL for the mutiwoven server is pointing to the staging deployed URL. If you want it to point to the local server, you will have to make sure the multiwoven server is setup locally on your machine.
Follow the steps [here](https://github.com/Multiwoven/multiwoven-server/tree/main?tab=readme-ov-file#local-setup) to set it up locally.

## Contributing

The contribution documentation is available [here](https://github.com/Multiwoven/multiwoven-ui/blob/main/CONTRIBUTING.md)

## Need Help?

We are always here to help you. If you have any questions or need help with Multiwoven, please feel free to reach out to us on [Slack](https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g). We are open to discuss new ideas, features, and improvements.

## License

Multiwoven is open-source under the GNU Affero General Public License Version 3 (AGPLv3) or any later version.
