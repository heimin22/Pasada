#!/bin/bash

# run flutter tests
echo "Running Flutter tests..."
docker-compose exec flutter-dev flutter test
