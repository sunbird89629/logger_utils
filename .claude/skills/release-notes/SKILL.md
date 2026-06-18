---
name: release-notes
description: Generate CHANGELOG entries from git history
disable-model-invocation: true
---

# Release Notes Generator

Generate CHANGELOG entries for a new release based on git commit history.

## Usage

```
/release-notes v0.0.2
```

## Process

1. **Get the version tag**: Use the provided version argument (e.g., `v0.0.2`)

2. **Find the previous release**:
   ```bash
   git describe --tags --abbrev=0 HEAD~1 2>/dev/null || git log --reverse --format="%H" | head -1
   ```

3. **Get commits since last release**:
   ```bash
   git log <prev-tag>..HEAD --oneline --no-merges
   ```

4. **Categorize commits** by conventional commit prefix:
   - `feat:` → ✨ Features
   - `fix:` → 🐛 Bug Fixes
   - `refactor:` → ♻️ Refactoring
   - `docs:` → 📚 Documentation
   - `test:` → ✅ Tests
   - `chore:` → 🔧 Chores
   - `style:` → 💅 Style
   - `perf:` → ⚡ Performance

5. **Generate the CHANGELOG entry**:

```markdown
## 0.0.2 (2026-06-18)

### ✨ Features
- add LoggerHttp and LoggingClient for HTTP request/response logging
- truncate long string values in JSON bodies (maxStringLen)
- add logHeader toggle to prettyResponse

### ♻️ Refactoring
- guard lazy logging in infoResponse/infoJson when level is disabled
- extract status line helper

### 🐛 Bug Fixes
- keep status line metadata on one line

### ✅ Tests
- add prettyResponse test suite
```

6. **Determine the commit SHA** for the release:
   - Use `HEAD` SHA (short form) for the current branch:
     ```bash
     git rev-parse --short HEAD
     ```
   - Include it in the version header: `## 0.0.2 (commit-sha)`

7. **Update pubspec.yaml version**:
   - Read the existing `pubspec.yaml`
   - Update the `version:` field to match the new version
   - This is the canonical version source for Dart packages

8. **Update CHANGELOG.md**:
   - Read the existing `CHANGELOG.md`
   - Prepend the new entry (with SHA) after the title
   - Keep the existing version entries unchanged below it
   - Write the updated file

9. **Create a git tag**:
   ```bash
   git tag -a v0.0.2 -m "v0.0.2: <brief description>" <commit-sha>
   ```

## Output

- Print the generated release notes to the user
- Ask if they want to update `CHANGELOG.md` and `pubspec.yaml`
- If yes, update both files and commit:
  ```bash
  git add CHANGELOG.md pubspec.yaml
  git commit -m "docs: update CHANGELOG for v0.0.2 and bump version"
  ```
- Ask if they want to create and push the git tag:
  ```bash
  git tag -a <version> -m "<version>: <brief description>" <commit-sha>
  git push origin <version>
  git push origin --tags
  ```

## Example

User: `/release-notes v0.0.2`

Claude:
1. Gets commits since v0.0.1
2. Categorizes them
3. Generates formatted release notes with SHA
4. Shows the preview
5. Asks to update CHANGELOG.md, pubspec.yaml, and create tag
6. Updates CHANGELOG.md (version header with SHA), bumps pubspec.yaml version
7. Commits both files
8. Creates git tag and pushes

## Notes

- **Versioning scheme**: start from `0.0.1` and increment the patch number by
  one each release (`0.0.1` → `0.0.2` → `0.0.3` → …). Do not bump minor/major.
- **Version header format**: `## 0.0.2 (commit-sha)` — include the short SHA
- Only include meaningful commits (skip `chore:` commits like "apply dart format" unless they're significant)
- Group related commits together
- Use the commit message as-is (don't rewrite)
- If a commit has a body, use the body as the description
- **pubspec.yaml** is the canonical version source for Dart packages — always update it
- **git tags** should be annotated (`-a`) with a brief description message
- Push tags separately after the commit is pushed
