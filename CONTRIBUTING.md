# Contributing to Firestore ODM

Welcome! We're excited that you're interested in contributing to Firestore ODM. This guide will help you get started.

## 🚀 Quick Start

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) (>=3.8.1)
- [Flutter](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- [Git](https://git-scm.com/)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/SylphxAI/firestore_odm.git
   cd firestore_odm
   ```

2. **Install Melos globally**
   ```bash
   dart pub global activate melos
   ```

3. **Bootstrap the workspace**
   ```bash
   melos bootstrap
   ```

4. **Verify setup**
   ```bash
   melos run check
   ```

## 📋 Development Workflow

### Available Commands

| Command | Description |
|---------|-------------|
| `melos run check` | Run all quality checks (format, analyze, test) |
| `melos run format` | Format all Dart code |
| `melos run format:check` | Check if code is properly formatted |
| `melos run analyze` | Run static analysis |
| `melos run test:all` | Run all tests |
| `melos run test:unit` | Run unit tests only |
| `melos run test:integration` | Run integration tests only |
| `melos run build:example` | Generate code for examples |
| `melos run clean` | Clean all build artifacts |

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our style guidelines
   - Add tests for new functionality
   - Update documentation as needed

3. **Run quality checks**
   ```bash
   melos run check
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## 🧪 Testing

### Running Tests

- **All tests**: `melos run test:all`
- **Unit tests**: `melos run test:unit`
- **Integration tests**: `melos run test:integration`
- **Specific package**: `melos run test --scope=firestore_odm`

### Writing Tests

- Place unit tests in `test/` directory
- Use descriptive test names
- Follow the AAA pattern (Arrange, Act, Assert)
- Mock external dependencies

Example:
```dart
import 'package:test/test.dart';
import 'package:firestore_odm/firestore_odm.dart';

void main() {
  group('FirestoreODM', () {
    test('should create collection reference', () {
      // Arrange
      const collectionPath = 'users';
      
      // Act
      final collection = FirestoreODM.collection(collectionPath);
      
      // Assert
      expect(collection.path, equals(collectionPath));
    });
  });
}
```

## 📝 Code Style

### Formatting

We use `dart format` with default settings. Run `melos run format` to format your code.

### Linting

We use `very_good_analysis` for linting. Run `melos run analyze` to check for issues.

### Naming Conventions

- **Classes**: PascalCase (`FirestoreCollection`)
- **Methods/Variables**: camelCase (`getUserById`)
- **Constants**: camelCase (`maxRetryCount`)
- **Files**: snake_case (`firestore_collection.dart`)

## 📦 Package Structure

```
packages/
├── firestore_odm_annotation/     # Pure annotations
├── firestore_odm/                # Core ODM functionality
└── firestore_odm_builder/        # Code generation
flutter_example/                   # Example application
```

### Adding Dependencies

1. Add to appropriate `pubspec.yaml`
2. Run `melos bootstrap`
3. Update documentation if needed

## 🔄 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Creating a Release

1. **Ensure all tests pass**
   ```bash
   melos run check
   ```

2. **Preview version changes**
   ```bash
   melos run version:check
   ```

3. **Create release via GitHub Actions**
   - Go to Actions > Release
   - Choose version type (patch/minor/major)
   - Run workflow

### Manual Release (if needed)

```bash
# Version packages
melos version --patch --yes

# Publish (dry run first)
melos run publish:dry-run
melos run publish
```

## 🐛 Bug Reports

When reporting bugs, please include:

- **Description**: Clear description of the issue
- **Steps to reproduce**: Minimal reproduction steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: Dart/Flutter versions, OS, etc.
- **Code sample**: Minimal code that demonstrates the issue

## ✨ Feature Requests

When requesting features:

- **Use case**: Explain why this feature is needed
- **Proposed solution**: How you think it should work
- **Alternatives**: Other solutions you've considered
- **Examples**: Code examples of how it would be used

## 📚 Documentation

- Update relevant documentation when making changes
- Add code examples for new features
- Keep API documentation up to date
- Update CHANGELOG.md for significant changes

## 🤝 Code of Conduct

Please be respectful and constructive in all interactions. We want to maintain a welcoming environment for all contributors.

## ❓ Questions

If you have questions:

1. Check existing [issues](https://github.com/SylphxAI/firestore_odm/issues)
2. Search [discussions](https://github.com/SylphxAI/firestore_odm/discussions)
3. Create a new discussion or issue

## 🙏 Thank You

Thank you for contributing to Firestore ODM! Your contributions help make this project better for everyone.