# Release Guide

This guide explains how to use the CI/CD workflows for nnInteractive Slicer Server.

## 🔧 Initial Setup

### Step 1: Set Up Trusted Publishing for PyPI/TestPyPI

The workflows use **Trusted Publishing** (OpenID Connect) - the modern, secure way to publish to PyPI without API tokens.

#### For TestPyPI (test releases):

**Set up Trusted Publisher on TestPyPI** (before package exists):

1. Go to: https://test.pypi.org/manage/account/publishing/
2. Scroll to **"Pending publishers"** section
3. Click **"Add a new pending publisher"**
4. Fill in:
   - **PyPI Project Name**: `nninteractive-slicer-server`
   - **Owner**: `coendevente` (your GitHub username/org)
   - **Repository name**: `SlicerNNInteractive`
   - **Workflow filename**: `test-release.yml`
   - **Environment name**: `test`
5. Click **"Add"**

This creates a "reservation" that allows your GitHub workflow to create and publish the package automatically on first release.

#### For PyPI (production releases):

**Set up Trusted Publisher on PyPI** (before package exists):

1. Go to: https://pypi.org/manage/account/publishing/
2. Scroll to **"Pending publishers"** section
3. Click **"Add a new pending publisher"**
4. Fill in:
   - **PyPI Project Name**: `nninteractive-slicer-server`
   - **Owner**: `coendevente` (your GitHub username/org)
   - **Repository name**: `SlicerNNInteractive`
   - **Workflow filename**: `release.yml`
   - **Environment name**: `production`
5. Click **"Add"**

This creates a "reservation" that allows your GitHub workflow to create and publish the package automatically on first release.

**Benefits of Trusted Publishing:**
- ✅ No API tokens to manage or rotate
- ✅ More secure (automatic OIDC authentication)
- ✅ Scoped to specific workflows and repositories
- ✅ Recommended by PyPI

### Step 2: Create GitHub Environments

Go to **Settings → Environments** and create two environments:

1. **`test`** - For test releases (TestPyPI, Docker test tags)
2. **`production`** - For production releases (PyPI, Docker official tags)

#### Optional: Add Production Protection

For the `production` environment, you can add protection rules:
- ✅ **Required reviewers**: Require manual approval before production deploys
- ✅ **Deployment branches**: Limit to `main` branch only (already enforced by workflow)

This adds an extra safety layer for production releases.

### Step 3: Add Docker Hub Secrets

Add Docker Hub credentials to both environments:

#### For `test` environment:

**Settings → Environments → test → Add secret**

1. **DOCKERHUB_USERNAME**
   - Your Docker Hub username (e.g., `coendevente`)

2. **DOCKERHUB_TOKEN**
   - Go to https://hub.docker.com/settings/security
   - Create a new access token
   - Add it to the `test` environment

#### For `production` environment:

**Settings → Environments → production → Add secret**

1. **DOCKERHUB_USERNAME**
   - Your Docker Hub username (same as above)

2. **DOCKERHUB_TOKEN**
   - Same Docker Hub access token as above (or create a separate one for production)

## 📋 Workflows Overview

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers:** All pushes and PRs to `main` or `develop` branches

**What it does:**
- Runs tests
- Builds the Python package (without publishing)
- Builds the Docker image (without pushing)
- Checks version consistency between `pyproject.toml` and git tags

**No setup required** - runs automatically on PRs.

---

### 2. Test Release Workflow (`.github/workflows/test-release.yml`)

**Triggers:** Tags matching `test-v*` (e.g., `test-v0.2.1-beta`)

**What it does:**
- Publishes to **TestPyPI** (https://test.pypi.org)
- Pushes Docker image with tags:
  - `coendevente/nninteractive:test-0.2.1-beta`
  - `coendevente/nninteractive:test-latest`
- Creates a GitHub prerelease

**Use this for:** Testing the release pipeline on feature branches

#### Example Usage:

```bash
# On your feature branch (e.g., 'feature/new-model')
git add .
git commit -m "Add new model support"

# Create a test release tag
git tag test-v0.2.1-beta1
git push origin test-v0.2.1-beta1

# GitHub Actions will publish to TestPyPI and Docker Hub with test tags
```

#### Testing the Published Packages:

```bash
# Test PyPI package
pip install --index-url https://test.pypi.org/simple/ \
            --extra-index-url https://pypi.org/simple/ \
            nninteractive-slicer-server==0.2.1-beta1

# Test Docker image
docker pull coendevente/nninteractive:test-0.2.1-beta1
docker run coendevente/nninteractive:test-0.2.1-beta1
```

---

### 3. Production Release Workflow (`.github/workflows/release.yml`)

**Triggers:** Tags matching `v*.*.*` (e.g., `v0.2.1`) **on main branch only**

**What it does:**
- Verifies tag is on `main` branch
- Verifies version in `pyproject.toml` matches the tag
- Publishes to **PyPI** (https://pypi.org)
- Pushes Docker image with tags:
  - `coendevente/nninteractive:0.2.1`
  - `coendevente/nninteractive:latest`
- Creates an official GitHub release with changelog

**Use this for:** Official production releases

#### Pre-Release Checklist:

1. **Ensure you're on main branch:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Update version in `server/pyproject.toml`:**
   ```toml
   version = "0.2.1"
   ```

3. **Commit the version bump:**
   ```bash
   git add server/pyproject.toml
   git commit -m "Bump version to 0.2.1"
   git push origin main
   ```

4. **Create and push the release tag:**
   ```bash
   git tag v0.2.1
   git push origin v0.2.1
   ```

5. **GitHub Actions takes over:**
   - Validates everything
   - Publishes to PyPI and Docker Hub
   - Creates GitHub release

6. **Verify the release:**
   ```bash
   # Check PyPI
   pip install nninteractive-slicer-server==0.2.1

   # Check Docker Hub
   docker pull coendevente/nninteractive:0.2.1
   ```

## 🎯 Common Workflows

### Scenario 1: Testing a new feature

```bash
# On feature branch
git checkout -b feature/new-feature
# ... make changes ...
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# Test the release pipeline
git tag test-v0.3.0-alpha1
git push origin test-v0.3.0-alpha1

# Verify on TestPyPI and Docker Hub test tags
# If good, merge to main and do production release
```

### Scenario 2: Production release

```bash
# On main branch
git checkout main
git pull

# Update version in server/pyproject.toml to 0.3.0
vim server/pyproject.toml

git add server/pyproject.toml
git commit -m "Bump version to 0.3.0"
git push origin main

# Create release
git tag v0.3.0
git push origin v0.3.0

# Done! Check GitHub Actions for progress
```

### Scenario 3: Hotfix release

```bash
# Create hotfix branch from main
git checkout main
git pull
git checkout -b hotfix/critical-bug

# Fix the bug
git add .
git commit -m "Fix critical bug in inference"

# Test with test release first
git tag test-v0.2.2
git push origin test-v0.2.2

# Verify the fix works, then merge to main
git checkout main
git merge hotfix/critical-bug

# Update version and release
vim server/pyproject.toml  # Change to 0.2.2
git add server/pyproject.toml
git commit -m "Bump version to 0.2.2"
git push origin main

git tag v0.2.2
git push origin v0.2.2
```

## ❌ Common Errors

### "Tag must be on main branch"
- Production tags (v*) can only be created from main branch
- Use test tags (test-v*) for feature branches

### "Version mismatch between pyproject.toml and tag"
- Update `server/pyproject.toml` to match your tag version
- If tagging v0.2.1, pyproject.toml should have version = "0.2.1"

### "Invalid credentials for PyPI"
- Check that PYPI_API_TOKEN or TEST_PYPI_API_TOKEN is correctly set
- Regenerate tokens if needed

### "Docker Hub authentication failed"
- Verify DOCKERHUB_USERNAME and DOCKERHUB_TOKEN are correct
- Ensure you're using an access token, not your password

## 📦 Version Numbering

Follow semantic versioning (semver):

- **Major** (v1.0.0): Breaking changes
- **Minor** (v0.2.0): New features, backward compatible
- **Patch** (v0.2.1): Bug fixes, backward compatible

For test releases, use descriptive suffixes:
- `test-v0.3.0-alpha1`: Early alpha testing
- `test-v0.3.0-beta1`: Feature-complete beta
- `test-v0.3.0-rc1`: Release candidate

## 🔍 Monitoring Releases

- **GitHub Actions**: Check the Actions tab for workflow runs
- **PyPI**: https://pypi.org/project/nninteractive-slicer-server/
- **TestPyPI**: https://test.pypi.org/project/nninteractive-slicer-server/
- **Docker Hub**: https://hub.docker.com/r/coendevente/nninteractive

## 🆘 Need Help?

If you encounter issues:
1. Check the GitHub Actions logs for detailed error messages
2. Verify all secrets are correctly configured
3. Ensure version numbers match between pyproject.toml and tags
4. Make sure production tags are created from main branch
