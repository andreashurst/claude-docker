# Roadmap 🗺️

Claude Docker development roadmap and future plans.

## Current Version: 3.2.x

**Status**: ✅ Production Ready

- ✅ Two optimized Docker images (dev, flow)
- ✅ 11 pre-configured MCP servers
- ✅ Automatic localhost mapping
- ✅ Persistent credential storage
- ✅ AI-powered git commits
- ✅ Full testing infrastructure
- ✅ CI/CD pipeline
- ✅ Comprehensive documentation
- ✅ Security policy
- ✅ Performance benchmarking

---

## Version 3.3.0 (Q2 2025)

**Focus**: Distribution & Package Management

### Planned Features

- [ ] **Homebrew Formula**
  - `brew install andreashurst/tap/claude-docker`
  - Automatic updates via brew
  - MacOS and Linux support

- [ ] **APT Repository**
  - Debian/Ubuntu package
  - `sudo apt install claude-docker`
  - Auto-update integration

- [ ] **Snap Package**
  - Cross-platform snap package
  - `snap install claude-docker`
  - Automatic confinement

- [ ] **Windows Support**
  - WSL2 automatic detection
  - Windows installer script
  - PowerShell completions

---

## Version 3.4.0 (Q3 2025)

**Focus**: Advanced Features & Extensibility

### Planned Features

- [ ] **Plugin System**
  - Custom MCP server loading
  - Third-party plugin registry
  - Plugin marketplace

- [ ] **Configuration TUI**
  - Interactive setup wizard
  - Settings management UI
  - MCP server configuration

- [ ] **Project Templates**
  - Pre-configured project starters
  - Framework-specific templates
  - Custom template support

- [ ] **Container Profiles**
  - Minimal, standard, full profiles
  - Memory/CPU constraints
  - Custom resource limits

---

## Version 4.0.0 (Q4 2025)

**Focus**: Cloud & Team Features

### Planned Features

- [ ] **Multi-User Support**
  - Team credential sharing
  - Shared MCP configurations
  - Access control lists

- [ ] **Cloud Integration**
  - Remote Docker support
  - Cloud credential sync
  - Distributed testing

- [ ] **Advanced Monitoring**
  - Prometheus metrics
  - Grafana dashboards
  - Performance analytics

- [ ] **Enhanced Security**
  - SELinux policies
  - AppArmor profiles
  - Signed images

---

## Future Considerations

### Under Investigation

- **Kubernetes Support**: Helm charts for K8s deployments
- **Remote Development**: VS Code Remote Container integration
- **Mobile Support**: iOS/Android testing in containers
- **AI Enhancements**: More AI-powered automation
- **Language Support**: Additional programming languages
- **Database Support**: PostgreSQL, MongoDB, Redis containers

### Community Requests

Track feature requests in [GitHub Discussions](https://github.com/andreashurst/claude-docker/discussions).

Vote on features using 👍 reactions on issues.

---

## Release Schedule

- **Major versions** (X.0.0): Yearly, breaking changes allowed
- **Minor versions** (x.X.0): Quarterly, new features
- **Patch versions** (x.x.X): Monthly, bug fixes and security

---

## Contributing to Roadmap

We welcome roadmap suggestions! Please:

1. Check existing [feature requests](https://github.com/andreashurst/claude-docker/labels/enhancement)
2. Open a [discussion](https://github.com/andreashurst/claude-docker/discussions) for major features
3. Submit detailed [feature request](https://github.com/andreashurst/claude-docker/issues/new?template=feature_request.yml)

---

## Deprecated Features

### Removed in 3.0.0
- Support for Docker versions < 20.10
- Legacy MCP configuration format
- Python 2.x support

### Planned Deprecation
- Node.js 18 support (EOL April 2025)
- PHP 8.2 support when 8.4 is stable
- Alpine 3.18 base (moving to 3.20+)

---

**Last Updated**: 2024-12-30
