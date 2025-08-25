#!/bin/bash

# run flutter web server
echo "Starting Flutter web development server..."
docker-compose exec flutter-dev flutter run -d web-server --web-port 8000 --web-hostname 0.0.0.0
