# Claude Development Environment

A modern Docker-based development environment for [Claude Code](https://docs.anthropic.com/claude/reference/claude-code) with automatic setup, localhost integration, and team-ready configurations.

## 🚀 Quick Start

```bash
# Clone repository
git clone <your-repo-url>
cd claude-development-environment

# Install both environments
chmod +x install.sh
./install.sh

# Start developing
claude-dev    # Basic development environment
claude-flow   # Advanced environment with Claude Flow
```

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [Team Setup](#team-setup)
- [Advanced Usage](#advanced-usage)
- [Contributing](#contributing)

## 🎯 Overview

This project provides two complementary Docker-based environments for Claude Code development:

### Claude Dev
- **Purpose**: Basic Claude Code development
- **Base Image**: Node.js 22-alpine
- **Focus**: Simple, fast setup for individual development
- **Best for**: Quick prototyping, learning Claude Code, individual projects
- **Features**: Essential development tools, lightweight container

### Claude Flow
- **Purpose**: Advanced development with Claude Flow integration
- **Base Image**: Node.js 22-slim with additional tools
- **Focus**: Advanced workflows, browser automation, full-stack development
- **Best for**: Complex projects, team workflows, production applications
- **Features**: Deno runtime, Playwright, SQLite3, Python3

Both environments can run **simultaneously** and are completely isolated from each other.

## 📋 Prerequisites

### System Requirements
- **macOS** (12.0+) or **Linux** (Ubuntu 20.04+)
- **Docker Desktop** (4.0+) or **Docker Engine** (24.0+)
- **4GB RAM** minimum (8GB+ recommended for Claude Flow)
- **Internet connection** (for package downloads)
- **2GB free disk space** minimum

### Software Dependencies
- Docker & Docker Compose
- Git (for repository management)
- Terminal/Shell access

### Installation Check
```bash
# Verify Docker installation
docker --version
docker compose version

# Verify Docker is running
docker info
```

## 🔧 Installation

### Automatic Installation

The installer handles everything automatically:
- ✅ System requirements validation
- ✅ Docker environment setup
- ✅ Container configuration with security hardening
- ✅ Global command installation
- ✅ Network and DNS configuration
- ✅ Cleanup of old installations
- ✅ Health checks and monitoring

### Single Installation Script

```bash
# Download and install both environments
chmod +x install.sh
./install.sh
```

**Features:**
- Color-coded output for better visibility
- Comprehensive error handling
- Input validation and security checks
- Automatic dependency verification
- Clean installation process

### Manual Installation

If you prefer manual setup:

```bash
# Create configuration directory
mkdir -p ~/.config/claude

# Copy compose files
cp docker/docker-compose.dev.yml ~/.config/claude/
cp docker/docker-compose.flow.yml ~/.config/claude/

# Install scripts globally (automatically done by install.sh)
# Scripts are OS-specific and installed based on Docker Compose version:
# - Docker Compose v2: scripts/claude-dev-v2 -> claude-dev
# - Docker Compose v1: scripts/claude-dev-v1 -> claude-dev
sudo chmod +x /usr/local/bin/claude-*
```

## 🎮 Usage

### Starting Development

**Claude Dev (Basic):**
```bash
claude-dev
```

**Claude Flow (Advanced):**
```bash
claude-flow
```

### Interactive Setup

Both commands will prompt for:

1. **Frontend URL**
   - Default: `localhost:3000`
   - Input: Any localhost URL (e.g., `localhost:8080`, `localhost:5173`)

**Note:** The scripts automatically use the current directory as project path for consistency with Docker Compose naming and volume mounts.

### Container Management

```bash
# Check running containers
docker ps

# View container logs
docker logs claude-dev      # or claude-flow
docker logs -f claude-dev   # follow logs

# Connect to container manually
docker exec -it claude-dev sh
docker exec -it claude-flow sh

# Stop containers
docker stop claude-dev claude-flow
```

### Development Workflow

1. **Navigate to your project**
   ```bash
   cd /path/to/your/project
   ```

2. **Start Environment**
   ```bash
   claude-dev  # or claude-flow
   ```

3. **Project Setup**
   - Configure frontend URL (e.g., localhost:5173)
   - Wait for installation (first time only)

4. **Development**
   ```bash
   # Inside container
   claude                           # Start Claude Code
   claude "analyze this codebase"   # Direct command
   claude -p "review changes"       # Print mode
   ```

4. **Testing External Services**
   ```bash
   # Test frontend connectivity
   curl http://localhost:3000

   # Test API endpoints
   curl http://localhost:8080/api/health
   ```

## ⚙️ Configuration

### Global Configuration

Configuration files are stored in `~/.config/claude/`:

```
~/.config/claude/
├── docker-compose.claude-dev.yml
└── docker-compose.claude-flow.yml
```

### Container Configuration

**Working Directory:** `/var/www/html`
**User:** Non-root user (UID 1000)
**DNS Servers:** 8.8.8.8, 1.1.1.1
**Security:** `no-new-privileges` flag enabled

### Volume Mounts

```yaml
volumes:
  - ${PWD}:/var/www/html:cached           # Project files
  - claude-dev-cache:/home/claude/.cache  # NPM cache
  - claude-dev-npm:/home/claude/.npm      # NPM global packages
  - claude-dev-config:/home/claude/.config # Configuration
```

### Environment Variables

```yaml
environment:
  - NODE_ENV=development
  - CLAUDE_CONFIG_PATH=/home/claude/.config/claude
  - NPM_CONFIG_CACHE=/home/claude/.cache/npm
```

### Custom Configuration

You can modify the Docker Compose files for custom setups:

```bash
# Edit configuration
nano ~/.config/claude/docker-compose.dev.yml

# Add custom environment variables
# Modify resource limits
# Adjust security settings
```

## 🌟 Features

### Core Features

- ✅ **Isolated Environments** - Separate containers for different workflows
- ✅ **Localhost Integration** - Direct access to host services
- ✅ **Automatic Installation** - Zero-configuration setup with validation
- ✅ **Intelligent Waiting** - Robust handling of slow internet connections
- ✅ **Global Commands** - Available from any directory
- ✅ **Team Ready** - Consistent setup across team members
- ✅ **Security Hardened** - Non-root containers with restricted privileges
- ✅ **Resource Managed** - Configurable memory and CPU limits

### Claude Dev Features

- ✅ **Fast Setup** - Minimal installation time with Alpine Linux
- ✅ **Basic Toolkit** - Essential development tools (Node.js 22, Git, Bash)
- ✅ **Lightweight** - Optimized for resource efficiency
- ✅ **Quick Prototyping** - Immediate Claude Code access

### Claude Flow Features

- ✅ **Advanced Runtime** - Deno + Node.js dual runtime support
- ✅ **Browser Automation** - Playwright with Chromium pre-installed
- ✅ **Database Support** - SQLite3 with better-sqlite3 bindings
- ✅ **Multi-Language** - Python3 support for additional scripting
- ✅ **Extended Tooling** - Full development stack for complex projects

### Network & Connectivity

- ✅ **Host Network Access** - Connect to localhost services
- ✅ **DNS Resolution** - Reliable internet connectivity
- ✅ **External Service Testing** - Built-in connectivity testing
- ✅ **Port Flexibility** - Support for any local port

### Robustness Features

- ✅ **Retry Logic** - Automatic retry on network failures
- ✅ **Timeout Handling** - Graceful handling of slow connections
- ✅ **Progress Indicators** - Real-time installation progress
- ✅ **Error Recovery** - Helpful error messages and recovery steps

## 🔧 Troubleshooting

### Common Issues

**1. Docker Not Running**
```bash
# Error: Cannot connect to Docker daemon
# Solution: Start Docker Desktop or Docker service
sudo systemctl start docker  # Linux
open -a Docker  # macOS
```

**2. Permission Denied**
```bash
# Error: Permission denied
# Solution: Run installer with proper permissions
sudo ./install-claude-dev.sh
```

**3. Network Connection Issues**
```bash
# Error: Unable to fetch packages
# Solution: Check internet connection and DNS
ping 8.8.8.8
curl -I https://registry.npmjs.org
```

**4. Container Won't Start**
```bash
# Debug container issues
docker logs claude-dev
docker inspect claude-dev

# Clean restart
docker stop claude-dev && docker rm claude-dev
claude-dev
```

**5. Claude Code Not Found**
```bash
# Check installation in container
docker exec -it claude-dev sh
which claude
npm list -g @anthropic-ai/claude-code

# Manual installation
npm install -g @anthropic-ai/claude-code
```

### Installation Issues

**Slow Internet Connections:**
- Installers automatically handle slow connections
- Extended timeouts (up to 200+ seconds)
- Automatic retry logic
- Progress indicators show elapsed time

**Package Installation Failures:**
```bash
# View detailed logs
docker logs -f claude-dev

# Manual package installation
docker exec -it claude-dev sh
npm install -g @anthropic-ai/claude-code --verbose
```

**Path Issues:**
```bash
# Verify command installation
which claude-dev
which claude-flow

# Manual path check
echo $PATH
ls -la /usr/local/bin/claude-*
```

### Authentication Issues

**Claude Code Authentication:**
```bash
# In container
claude auth login    # Opens browser for OAuth
claude auth status   # Check authentication status

# Re-authenticate if needed
rm -rf ~/.config/claude-code/auth
claude auth login
```

### Performance Issues

**Container Resource Usage:**
```bash
# Monitor container resources
docker stats claude-dev

# Limit container resources (edit compose file)
services:
  claude-dev:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

## 👥 Team Setup

### Repository Setup

1. **Add to your project repository:**
   ```bash
   # Copy installer files to your repo
   cp install-claude-dev.sh your-project/
   cp install-claude-flow.sh your-project/

   # Commit and push
   git add install-claude-*.sh
   git commit -m "Add Claude development environment"
   git push
   ```

2. **Team onboarding:**
   ```bash
   # Each team member runs:
   git clone your-project
   cd your-project
   ./install-claude-dev.sh     # or install-claude-flow.sh
   ```

### Standardized Workflows

**Project Configuration:**
```bash
# Each team member navigates to project and starts
cd /path/to/your/project
claude-flow  # Consistent environment
# Frontend URL: localhost:3000  # Team standard
```

**Shared Configuration:**
- Consistent Docker environment
- Same Node.js and package versions
- Identical Claude Code setup
- Standardized development tools

### Best Practices

1. **Environment Consistency**
   - All team members use same installer version
   - Document frontend URL standards
   - Share project-specific configurations

2. **Version Control**
   - Include installer scripts in repository
   - Document any custom configurations
   - Tag installer versions for stability

3. **Team Communication**
   - Share authentication setup process
   - Document any project-specific Claude workflows
   - Establish container naming conventions

### Multi-Project Setup

```bash
# Project A
cd project-a
claude-dev    # Basic development

# Project B
cd project-b
claude-flow   # Advanced workflow

# Both can run simultaneously
docker ps     # Shows both containers
```

## 🚀 Advanced Usage

### Custom Docker Configurations

**Extending Base Configuration:**
```yaml
# ~/.config/claude/docker-compose.claude-dev.yml
services:
  claude-dev:
    # ... base configuration
    volumes:
      - ${PWD}:/var/www/html
      - ~/.ssh:/root/.ssh:ro          # SSH keys
      - ~/.gitconfig:/root/.gitconfig:ro  # Git config
    environment:
      - CUSTOM_VAR=value
```

**Adding Development Tools:**
```yaml
command: >
  sh -c "
    # Base installation
    apk add --no-cache git bash curl &&
    npm install -g @anthropic-ai/claude-code &&

    # Custom tools
    apk add --no-cache vim nano &&
    npm install -g eslint prettier &&

    exec tail -f /dev/null
  "
```

### Integration with External Services

**Database Connections:**
```bash
# In container
curl postgres://localhost:5432
curl mongodb://localhost:27017
```

**API Development:**
```bash
# Test APIs running on host
curl http://localhost:8080/api/v1/health
curl -X POST http://localhost:3001/webhook
```

**Frontend Frameworks:**
```bash
# Common frontend dev servers
curl http://localhost:3000    # React, Next.js
curl http://localhost:5173    # Vite
curl http://localhost:4200    # Angular
curl http://localhost:8000    # Django
```

### CI/CD Integration

**GitHub Actions Example:**
```yaml
# .github/workflows/claude-code.yml
name: Claude Code Analysis
on: [push, pull_request]

jobs:
  claude-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Claude Environment
        run: |
          chmod +x install-claude-dev.sh
          ./install-claude-dev.sh
      - name: Run Claude Analysis
        run: |
          echo "localhost:3000" | echo "${{ github.workspace }}" | claude-dev
```

**Automated Code Review:**
```bash
# Script for automated reviews
#!/bin/bash
# review-changes.sh

docker exec claude-dev sh -c "
  cd /var/www/html &&
  git diff HEAD~1 | claude -p 'Review these changes for security and best practices'
"
```

### Performance Optimization

**Container Optimization:**
```yaml
# Optimized for development
services:
  claude-dev:
    shm_size: 2gb           # Shared memory for better performance
    ulimits:
      nofile: 65536         # File descriptor limits
    sysctls:
      net.core.somaxconn: 1024
```

**Caching Strategy:**
```bash
# Pre-warm containers
docker-compose -f ~/.config/claude/docker-compose.claude-dev.yml pull
docker-compose -f ~/.config/claude/docker-compose.claude-flow.yml pull
```

### Development Automation

**Custom Commands:**
```bash
# ~/.bashrc or ~/.zshrc
alias cdev='claude-dev'
alias cflow='claude-flow'
alias clog='docker logs -f claude-dev'
alias csh='docker exec -it claude-dev sh'

# Project-specific commands
alias start-project='cd ~/projects/myapp && claude-dev'
```

**Automated Project Setup:**
```bash
#!/bin/bash
# quick-start.sh

PROJECT_NAME=$1
mkdir -p ~/projects/$PROJECT_NAME
cd ~/projects/$PROJECT_NAME

# Initialize project
git init
echo "# $PROJECT_NAME" > README.md

# Start Claude environment
echo "~/projects/$PROJECT_NAME" | echo "localhost:3000" | claude-flow
```

## 🔐 Security Considerations

### Container Security

**Isolation:**
- Containers run in isolated environments
- No privileged access required
- Network isolation with host access only when needed

**Volume Mounts:**
- Only project directories are mounted
- No access to sensitive host files
- Cache directories are containerized

**Network Security:**
- Host network mode for development only
- No exposed ports to external networks
- DNS configured for reliable resolution

### Authentication Security

**Claude Code Authentication:**
- OAuth-based authentication through browser
- Tokens stored in container-specific locations
- No shared authentication between environments

**Best Practices:**
- Use project-specific API keys when possible
- Regularly rotate authentication tokens
- Monitor API usage and costs

### Data Protection

**Project Data:**
- All project files remain on host system
- Container only provides execution environment
- No data persistence in container layers

**Backup Considerations:**
- Container caches can be recreated
- Authentication tokens should be backed up
- Project-specific configurations in version control

## 📈 Monitoring and Logging

### Container Monitoring

**Resource Usage:**
```bash
# Monitor all Claude containers
docker stats claude-dev claude-flow

# Detailed container information
docker inspect claude-dev
```

**Log Management:**
```bash
# Follow logs in real-time
docker logs -f claude-dev

# Export logs for analysis
docker logs claude-dev > claude-dev.log

# Log rotation
docker system prune  # Clean old logs
```

### Performance Metrics

**Installation Time Tracking:**
- Installers provide progress indicators
- Network speed affects installation time
- Typical installation: 2-5 minutes

**Development Metrics:**
- Container startup time: ~10-30 seconds
- Claude Code initialization: ~5-15 seconds
- Memory usage: ~500MB-1GB per container

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/claude-development-environment
   cd claude-development-environment
   ```
3. **Test changes:**
   ```bash
   # Test installers
   ./install-claude-dev.sh
   ./install-claude-flow.sh
   ```

### Testing Guidelines

**Test Matrix:**
- ✅ macOS (Intel & Apple Silicon)
- ✅ Linux (Ubuntu, Debian, CentOS)
- ✅ Docker Desktop & Docker Engine
- ✅ Slow and fast internet connections

**Test Scenarios:**
```bash
# Clean installation
./install-claude-dev.sh

# Upgrade installation
./install-claude-dev.sh  # Run twice

# Parallel installation
./install-claude-dev.sh && ./install-claude-flow.sh

# Container interactions
claude-dev &
claude-flow &
docker ps  # Both should run simultaneously
```

### Code Style

**Shell Scripts:**
- Use `#!/bin/bash` shebang
- Follow POSIX compatibility when possible
- Include error handling with `set -e`
- Use meaningful variable names

**Docker Compose:**
- Use version 3.8+ syntax
- Include comments for complex configurations
- Follow service naming conventions
- Use explicit tags for base images

### Submission Process

1. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test thoroughly**

3. **Update documentation:**
   - Update README.md for new features
   - Add troubleshooting entries if needed
   - Include usage examples

4. **Submit pull request:**
   - Clear description of changes
   - Test results and screenshots
   - Reference any related issues

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

**Documentation:**
- [Claude Code Documentation](https://docs.anthropic.com/claude/reference/claude-code)
- [Claude Flow Documentation](https://github.com/anthropics/claude-flow)
- [Docker Documentation](https://docs.docker.com/)

**Community:**
- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share experiences
- Wiki: Additional examples and tutorials

**Commercial Support:**
- [Anthropic Support](https://support.anthropic.com)
- [Anthropic Console](https://console.anthropic.com)

### Issue Reporting

When reporting issues, please include:

1. **Environment Information:**
   ```bash
   # Include output of these commands
   uname -a                    # System information
   docker --version           # Docker version
   docker compose version     # Compose version
   ```

2. **Error Details:**
   - Complete error messages
   - Container logs: `docker logs claude-dev`
   - Steps to reproduce

3. **Configuration:**
   - Which installer used (claude-dev or claude-flow)
   - Any custom configurations
   - Network environment details

---

**🎯 Ready to start developing with Claude? Run the installer and you'll be coding in minutes!**

```bash
# Get started now
git clone <your-repo-url>
cd claude-development-environment
./install-claude-dev.sh
```


**Happy Coding! 🚀**
