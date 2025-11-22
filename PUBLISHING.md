# Publishing Guide

This guide explains how to publish the SyncVault package to pub.dev.

## Prerequisites

- Dart SDK installed
- pub.dev account created
- Package maintainer permissions

## Pre-Publishing Checklist

### 1. Code Quality

- [ ] All tests pass: `flutter test`
- [ ] Code is properly formatted: `dart format .`
- [ ] No analyzer issues: `dart analyze`
- [ ] Documentation is complete
- [ ] Example app works correctly

### 2. Package Files

- [ ] `pubspec.yaml` is properly configured
- [ ] `README.md` is comprehensive
- [ ] `CHANGELOG.md` is updated
- [ ] `LICENSE` file exists
- [ ] Example code is included
- [ ] API documentation is complete

### 3. Version Management

Update version in `pubspec.yaml` following [semantic versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Example:
```yaml
version: 1.0.0
```

Update `CHANGELOG.md`:
```markdown
## 1.0.0

### Features
- Initial release
- Offline-first database
- Automatic sync
- Conflict resolution
- And more...
```

## Publishing Steps

### 1. Dry Run

First, perform a dry run to check for issues:

```bash
flutter pub publish --dry-run
```

Review the output for:
- Missing files
- Incorrect metadata
- Large file warnings
- License issues

### 2. Run Tests

Ensure all tests pass:

```bash
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
```

### 3. Update Documentation

Generate API documentation:

```bash
dart doc .
```

Review generated docs in `doc/api/` directory.

### 4. Publish

When everything looks good:

```bash
flutter pub publish
```

You'll be asked to confirm. Type 'y' to proceed.

### 5. Verify Publication

After publishing:

1. Visit https://pub.dev/packages/sync_vault
2. Check that:
   - Version number is correct
   - README displays properly
   - Example code is visible
   - API docs are generated
   - Score is good (aim for 130+)

## Post-Publishing

### 1. Tag Release

Tag the release in git:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 2. Create GitHub Release

1. Go to GitHub repository
2. Click "Releases"
3. Click "Draft a new release"
4. Select the tag
5. Add release notes from CHANGELOG
6. Publish release

### 3. Announce

Share the release:
- Twitter/X
- Reddit (r/FlutterDev)
- Dev.to
- Medium
- Your blog

## Continuous Publishing

### Automated Publishing with GitHub Actions

Create `.github/workflows/publish.yml`:

```yaml
name: Publish to pub.dev

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      - name: Publish
        run: flutter pub publish --force
        env:
          PUB_CREDENTIALS: ${{ secrets.PUB_CREDENTIALS }}
```

## Package Scoring

pub.dev scores packages on:

1. **Likes**: Community popularity
2. **Pub Points**: Quality metrics (max 130)
   - Follow Dart file conventions
   - Provide documentation
   - Support multiple platforms
   - Pass static analysis
3. **Popularity**: Download metrics

### Improving Your Score

- Add comprehensive documentation
- Include working examples
- Support multiple platforms
- Maintain code quality
- Respond to issues quickly
- Keep dependencies updated

## Versioning Strategy

### Development Versions

Use pre-release versions during development:

```yaml
version: 1.1.0-dev.1
version: 1.1.0-beta.1
version: 1.1.0-rc.1
```

### Stable Releases

Only publish stable versions to pub.dev:

```yaml
version: 1.1.0
```

## Common Issues

### Issue: Package validation failed

**Solution**: Run `flutter pub publish --dry-run` and fix all warnings.

### Issue: Version already exists

**Solution**: Increment the version number in `pubspec.yaml`.

### Issue: Large package size

**Solution**: Add files to `.pubignore`:

```
.git/
.github/
.vscode/
.idea/
*.log
test/
example/build/
```

### Issue: Missing documentation

**Solution**: Add doc comments to all public APIs:

```dart
/// Creates a new instance of [SyncVaultDatabase].
///
/// The [config] parameter specifies the database configuration.
///
/// Example:
/// ```dart
/// final db = SyncVaultDatabase(config: config);
/// ```
```

## Best Practices

1. **Test before publishing**: Always run tests and dry-run
2. **Semantic versioning**: Follow semver strictly
3. **Changelog**: Keep detailed changelog
4. **Breaking changes**: Increment major version
5. **Documentation**: Keep docs up to date
6. **Examples**: Provide working examples
7. **Issues**: Respond to issues promptly
8. **Dependencies**: Keep dependencies updated

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Semantic Versioning](https://semver.org/)
- [Writing API Documentation](https://dart.dev/guides/language/effective-dart/documentation)

## Maintenance

### Regular Updates

- Monitor for security vulnerabilities
- Update dependencies quarterly
- Review and respond to issues weekly
- Update documentation as needed
- Publish patches for critical bugs

### Deprecation Policy

When deprecating features:

1. Mark as deprecated with `@Deprecated` annotation
2. Provide migration path in documentation
3. Keep deprecated code for at least one major version
4. Announce in changelog and release notes

Example:

```dart
@Deprecated('Use newMethod instead. Will be removed in v2.0.0')
void oldMethod() {
  // ...
}
```

## Support

For publishing issues:
- pub.dev support: https://github.com/dart-lang/pub-dev/issues
- Dart SDK issues: https://github.com/dart-lang/sdk/issues
