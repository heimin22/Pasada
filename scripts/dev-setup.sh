#!/bin/bash

# development setup script
echo "Setting up Pasada Flutter development environment..."

# build the development container
echo "Building development container..."
docker-compose build flutter-dev

# start the development environment
echo "Starting development environment..."
docker-compose up -d flutter-dev

# enter the container
echo "Entering development container..."
docker-compose exec flutter-dev bash