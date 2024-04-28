# Stage 0: Base image for dependencies
# Use a Node.js image to install dependencies
FROM node:18 as dependencies

# Set the working directory in the Docker container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock if using Yarn)
COPY package*.json ./

# Install dependencies with a large timeout to handle potential network issues
RUN npm install --timeout=3600000

# Stage 1: Build the application using the dependencies from the previous stage
FROM node:18 as build-stage

# Set the working directory
WORKDIR /app

# Copy installed dependencies from the dependencies stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy the rest of your application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve the application with Express
FROM node:18 as serve-stage

# Set the working directory in the Docker container
WORKDIR /app

# Install only production dependencies for Express
RUN npm install express --only=production

# Copy built assets from the build stage to the serve directory
COPY --from=build-stage /app/dist /app/dist

# Copy the Express server script
COPY server.js /app

# Expose the port your app runs on
EXPOSE 8000

# Start the Express server
CMD ["node", "server.js"]
