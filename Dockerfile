FROM ruby:3.4.5-slim

# Install system dependencies
RUN apt-get update -qq && \
  apt-get install -y \
  build-essential \
  curl \
  git \
  libpq-dev \
  libsqlite3-dev \
  libyaml-dev \
  pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Install latest Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get install -y nodejs

# Set working directory
WORKDIR /app

# Copy entrypoint
COPY entrypoint.sh /

# Copy package files first for better caching
COPY package*.json ./
COPY Gemfile* ./

# Install dependencies
RUN gem install bundler foreman && \
  bundle install && \
  npm install

# Copy application code
COPY . .

# Make bin/dev and entrypoint executable
RUN chmod +x bin/dev /entrypoint.sh

# Expose ports
EXPOSE 3000 5173

# Entrypoint для автоматической установки
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["./bin/dev"]
