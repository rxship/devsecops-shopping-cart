# Node 18 on Alpine - small attack surface, pinned version
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first to leverage Docker layer caching
COPY package*.json ./

# Reproducible install, skip devDependencies, clean cache
RUN npm ci --omit=dev && npm cache clean --force

# Copy the rest of the application code
COPY . .

# Create non-root user 'nodeapp' for security
RUN addgroup -S nodeapp && adduser -S nodeapp -G nodeapp \
    && chown -R nodeapp:nodeapp /app

# Switch to the non-root user
USER nodeapp

# Document the port
EXPOSE 3000

# Run node directly so it becomes PID 1 and receives signals properly
CMD ["node", "./bin/www"]