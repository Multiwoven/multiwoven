<div align="center">
  <a href="https://multiwoven.com?utm_source=github" target="_blank">
    <img src="https://res.cloudinary.com/dspflukeu/image/upload/v1706696350/Multiwoven/Logo_hrkaxj.png" alt="Multiwoven" width="240" />
  </a>
</div>
<br />
<p align="center">
  <a href="http://badge.fury.io/rb/multiwoven-integrations">
    <img src="https://badge.fury.io/rb/multiwoven-integrations.svg" alt="Gem Version">
  </a>
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
<h2 align="center">The open-source Reverse ETL platform for data teams</h2>

<p align="center">
  <br />
  <a href="https://docs.multiwoven.com" rel="">
    <strong>Explore the docs »</strong>
  </a>
  <br />
  <br />
  <a href="https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g">Slack</a>
    ·
    <a href="https://multiwoven.com">Website</a>
    ·
    <a href="https://github.com/Multiwoven/multiwoven-integrations/issues">Report Issues</a>
    ·
    <a href="https://github.com/orgs/Multiwoven/projects/4">Roadmap</a>
</p>

## Multiwoven Integrations

Multiwoven integrations is the collection of connectors built on top of [Multiwoven protocol](https://docs.multiwoven.com/guides/architecture/multiwoven-protocol).

Multiwoven protocol is an open source standard for moving data between data sources to any third-part destinations.
Anyone can build a connetor with basic ruby knowledge using the protocol.

## Prerequisites

Before you begin the installation, ensure you have the following dependencies installed:

- **MySQL Client**
  - Command: `brew install mysql-client`
  - Description: Required for database interactions.

- **Zstandard (zstd)**
  - Command: `brew install zstd`
  - Description: Needed for data compression and decompression.

- **OpenSSL 3**
  - Command: `brew install openssl@3`
  - Description: Essential for secure communication.


### Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add multiwoven-integrations


### Usage

#### Source
```
source = Multiwoven::Integrations::Source::[CONNECTOR_NAME]::Client.new
source.read(sync_config)
```
#### Destination

```
destination = Multiwoven::Integrations::Destination::[CONNECTOR_NAME]::Client.new
destination.write(sync_config, records)
```

#### Supported methods 
Please refer [Multiwoven Protocol](https://docs.multiwoven.com/guides/architecture/multiwoven-protocol) to understand more about the supported methods on source and destination

## Development

- **Install Dependencies**
  - Command: `bin/setup`
  - Description: After checking out the repo, run this command to install dependencies.

- **Run Tests**
  - Command: `rake spec`
  - Description: Run this command to execute the tests.

- **Interactive Prompt**
  - Command: `bin/console`
  - Description: For an interactive prompt that allows you to experiment, run this command.

- **Install Gem Locally**
  - Command: `bundle exec rake install`
  - Description: To install this gem onto your local machine, run this command.

- **Release New Version**
  - Steps:
    1. Update the version number in `rollout.rb`.
    2. Command: `bundle exec rake release`
    3. Description: This command will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Multiwoven/multiwoven-integrations). This project aims to be a safe, welcoming space for collaboration.

## Code of Conduct

Contributors are expected to adhere to the project's [code of conduct](https://github.com/Multiwoven/multiwoven-integrations/blob/main/CODE_OF_CONDUCT.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
