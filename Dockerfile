# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.0
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
    apt-get install --no-install-recommends -y build-essential autoconf automake libtool git libpq-dev libvips pkg-config m4 perl libltdl-dev

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

# # Navigate to the directory of the component you want to build
WORKDIR /multiwoven-dependencies/libiodbc-3.52.10

# Run autoreconf
RUN autoreconf -f -i

# Run configure and make install
RUN ./configure && \
    make && \
    make install

# Install the Snowflake ODBC driver
RUN wget https://sfc-repo.snowflakecomputing.com/odbc/linux/latest/snowflake-odbc-3.1.4.x86_64.deb -O snowflake-odbc.deb && \
    dpkg -i snowflake-odbc.deb || apt-get install -f

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

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Add a command here to list files in /rails/bin for debugging
RUN ls -l /rails/bin

# Create the required directories and Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/db /rails/log /rails/storage /rails/tmp && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
