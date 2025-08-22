#!/bin/bash

echo "Building Android app..."
docker-compose exec flutter-dev flutter build apk --release
