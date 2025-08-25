.PHONY: dev build-web build-android test clean help

# development
dev:
	@echo "Starting development environment..."
	@chmod +x scripts/dev-setup.sh
	@./scripts/dev-setup.sh

# Build commands
build-web:
	@echo "Building web version..."
	@docker-compose exec flutter-dev flutter build web --release

build-android:
	@echo "Building Android APK..."
	@docker-compose exec flutter-dev flutter build apk --release

# Testing
test:
	@echo "Running tests..."
	@docker-compose exec flutter-dev flutter test

# Clean up
clean:
	@echo "Cleaning up..."
	@docker-compose down -v
	@docker system prune -f

# Help
help:
	@echo "Available commands:"
	@echo "  dev          - Start development environment"
	@echo "  build-web    - Build web version"
	@echo "  build-android- Build Android APK"
	@echo "  test         - Run tests"
	@echo "  clean        - Clean up containers and volumes"