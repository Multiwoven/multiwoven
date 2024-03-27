# Stage 1: Build the application
# Use a Node.js image to build the app
FROM node:18 as build-stage

# Set the working directory in the Docker container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock if using Yarn)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve the application
# Use Nginx to serve the static files
FROM nginx:alpine

# Copy built assets from the build stage to the Nginx server directory
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration file
COPY server-config/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 8000
EXPOSE 8000

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]