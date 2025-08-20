# Docker Hub Setup Guide

## 📋 Prerequisites

1. **Docker Hub Account** - Create at [hub.docker.com](https://hub.docker.com)
2. **GitHub Repository** - Push this code to your GitHub repo
3. **GitHub Secrets** - Configure Docker Hub credentials

## 🔐 GitHub Secrets Setup

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub access token (not password!)

### Creating Docker Hub Access Token:
1. Login to [hub.docker.com](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Name it `github-actions` and select **Read, Write, Delete** permissions
5. Copy the token and add it as `DOCKER_PASSWORD` in GitHub secrets

## ⚙️ Configuration

### 1. ✅ Repository Configuration

All files are already configured for:

✅ **Already configured for andreashurst/claude-docker**

All files are pre-configured with:
- GitHub: `https://github.com/andreashurst/claude-docker`
- Docker Hub: `andreashurst/claude-docker`

### 2. Repository Structure

Your GitHub repository should look like this:

```
your-repo/
├── .github/workflows/build-and-push.yml
├── Dockerfile.dev
├── Dockerfile.flow
├── docker/
│   ├── docker-compose.dev.yml
│   ├── docker-compose.flow.yml
│   ├── entrypoint-dev.sh
│   └── entrypoint-flow.sh
└── README.md
```

## 🚀 Deployment Process

### Automatic Build (Recommended)

1. **Push to GitHub** - Images build automatically on:
   - Push to `main` or `develop` branch
   - Git tags (e.g., `v1.0.0`)
   - Pull requests (build only, no push)

2. **Docker Hub Images**:
   - `andreashurst/claude-docker:latest-dev`
   - `andreashurst/claude-docker:latest-flow`
   - Version tags: `andreashurst/claude-docker:v1.0.0-dev`

### Manual Build (For Testing)

```bash
# Build both images locally
docker build -f Dockerfile.dev -t andreashurst/claude-docker:latest-dev .
docker build -f Dockerfile.flow -t andreashurst/claude-docker:latest-flow .

# Push to Docker Hub
docker push andreashurst/claude-docker:latest-dev
docker push andreashurst/claude-docker:latest-flow
```

## 📦 Using the Images

### For End Users

```bash
# Pull and run dev environment
docker run -it --rm \
  -v $(pwd):/var/www/html \
  andreashurst/claude-docker:latest-dev

# Pull and run flow environment  
docker run -it --rm \
  -v $(pwd):/var/www/html \
  andreashurst/claude-docker:latest-flow
```

### With Docker Compose

```bash
# Update your docker-compose files first, then:
docker compose -f docker/docker-compose.dev.yml up
docker compose -f docker/docker-compose.flow.yml up
```

## 🎯 Image Tags Strategy

| Event | Dev Image | Flow Image |
|-------|-----------|------------|
| `main` branch | `latest-dev` | `latest-flow` |
| Git tag `v1.2.3` | `v1.2.3-dev`, `1.2-dev` | `v1.2.3-flow`, `1.2-flow` |
| PR #123 | `pr-123-dev` | `pr-123-flow` |
| `develop` branch | `develop-dev` | `develop-flow` |

## 🔍 Troubleshooting

### Build Failures
- Check GitHub Actions logs
- Verify Docker Hub credentials in secrets
- Ensure Dockerfile syntax is correct

### Permission Issues
- Use access token, not password for `DOCKER_PASSWORD`
- Ensure token has Write permissions

### Image Not Found
- Check if build completed successfully
- Verify image name matches exactly
- Public repos create public images automatically

## 📈 Benefits

✅ **Faster Development** - No local build time  
✅ **Consistent Environments** - Same image everywhere  
✅ **Version Control** - Tagged releases  
✅ **Multi-platform** - ARM64 + AMD64 support  
✅ **Automated** - Build on every commit  

## 🎉 Ready to Deploy!

1. ✅ Repository configured for `andreashurst/claude-docker`
2. Add GitHub secrets (`DOCKER_USERNAME` and `DOCKER_PASSWORD`)
3. Push to `https://github.com/andreashurst/claude-docker`
4. Watch the magic happen! 🚀