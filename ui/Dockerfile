# Stage 1: Build the application
# Use a Node.js image to build the app
FROM node:18 as build-stage

# Set the working directory in the Docker container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock if using Yarn)
COPY package*.json ./

# Set npm configuration to handle timeouts and retries
ENV NPM_CONFIG_LOGLEVEL=warn
ENV NPM_CONFIG_FETCH_RETRIES=5
ENV NPM_CONFIG_FETCH_RETRY_FACTOR=2
ENV NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=20000
ENV NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=120000

# Install dependencies
RUN npm ci

# Copy the rest of your application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve the application with Express
# Use Node.js image for runtime
FROM node:18 as serve-stage

# Set the working directory in the Docker container
WORKDIR /app

# Install Express
RUN npm install express

# Copy built assets from the build stage to the serve directory
COPY --from=build-stage /app/dist /app/dist

# Copy the Express server script
COPY server.js /app

# Expose the port your app runs on
EXPOSE 8000

# Start the Express server
CMD ["node", "server.js"]
