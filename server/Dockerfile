# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.4
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set environment variables for production
ENV BUNDLE_DEPLOYMENT=1
ENV BUNDLE_WITHOUT=development
ENV BUNDLE_PATH=/usr/local/bundle
ENV RAILS_ENV=production

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed for building, including Libtool
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential autoconf automake libtool git libpq-dev libvips pkg-config m4 perl libltdl-dev curl git wget unzip default-libmysqlclient-dev

# Copy and run the Oracle Instant Client installation script
COPY getoracleinstantclient.sh .
RUN chmod +x getoracleinstantclient.sh && ./getoracleinstantclient.sh

COPY getduckdb.sh .
COPY gethttpfsextension.sh .

# Make the scripts executable
RUN chmod +x getduckdb.sh gethttpfsextension.sh 

# Unzip and move DuckDB files
RUN ./getduckdb.sh
RUN unzip duckdb.zip -d libduckdb
RUN rm -rf duckdb.zip
RUN mv libduckdb/duckdb.* /usr/local/include
RUN mv libduckdb/libduckdb.so /usr/local/lib

# Unzip and Install DuckDB HTTPFS Extension 
RUN ./gethttpfsextension.sh

RUN ldconfig /usr/local/lib
# # Navigate to the directory of the component you want to build
WORKDIR /

# Clone the repository
RUN git clone https://github.com/Multiwoven/multiwoven-dependencies.git multiwoven-dependencies

WORKDIR /multiwoven-dependencies/unixODBC-2.3.11

# Run autoreconf
RUN autoreconf -f -i

# Run configure and make install
RUN ./configure && \
    make && \
    make install

# Install iodbc
RUN apt-get update -qq && \
    apt-get install -y libiodbc2 && \
    rm -rf /var/lib/apt/lists/*

# Hack for snowflake odbc driver
RUN apt-get update -qq && \
    apt-get install -y unixodbc && \
    rm -rf /var/lib/apt/lists/*

# Install free tds for tiny tds gem dependency
RUN apt-get install libc6-dev && \
    wget http://www.freetds.org/files/stable/freetds-1.4.10.tar.gz && \
    tar -xzf freetds-1.4.10.tar.gz && \
    cd freetds-1.4.10 && \
    ./configure --prefix=/usr/local --with-tdsver=7.4 && \
    make && \
    make install

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

# Install the Snowflake ODBC driver
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
ARG TARGETARCH=amd64

RUN if [ "$TARGETARCH" = "amd64" ] || [ "$TARGETARCH" = "x86_64" ]; then \
    wget https://sfc-repo.snowflakecomputing.com/odbc/linux/latest/snowflake-odbc-3.2.0.x86_64.deb -O snowflake-odbc.deb && \
    dpkg -i snowflake-odbc.deb || apt-get -y -f install; \
    elif [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then \
    wget https://sfc-repo.snowflakecomputing.com/odbc/linuxaarch64/3.2.0/snowflake-odbc-3.2.0.aarch64.deb -O snowflake-odbc.deb && \
    dpkg -i snowflake-odbc.deb || apt-get -y -f install; \
    else \
    echo "Unsupported architecture: $TARGETARCH" >&2; \
    exit 1; \
    fi

RUN apt-get update -qq && \
    apt-get install -y unzip 

RUN apt-get update -qq && \
    apt-get install -y libsasl2-modules-gssapi-mit

RUN if [ "$TARGETARCH" = "amd64" ] || [ "$TARGETARCH" = "x86_64" ]; then \
    wget --quiet https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.7.7/SimbaSparkODBC-2.7.7.1016-Debian-64bit.zip -O /tmp/databricks_odbc.zip && \
    unzip /tmp/databricks_odbc.zip -d /tmp && \
    dpkg -i /tmp/simbaspark_*.deb && \
    rm -rf /tmp/*; \
    fi
# ARM64 version of the Simba Spark ODBC driver is not currently available

# Change back to the root directory before copying the Rails app
# Rails app lives here
WORKDIR /rails

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Add a command here to list files in /rails/bin for debugging
RUN ls -l /rails/bin

# Create the required directories and Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/db /rails/log /rails/storage /rails/tmp && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp

USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]