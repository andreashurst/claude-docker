# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 3.2.x   | :white_check_mark: |
| 3.1.x   | :white_check_mark: |
| 3.0.x   | :x:                |
| < 3.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

### Email
Send an email to: security@example.com (replace with actual email)

### GitHub Security Advisory
Use GitHub's [Security Advisory](https://github.com/andreashurst/claude-docker/security/advisories/new) feature

### What to Include

Please include as much of the following information as possible:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: Within 7 days
  - High: Within 30 days
  - Medium: Within 90 days
  - Low: Next release cycle

## Security Measures

Claude Docker implements several security measures:

### Container Security
- ✅ Non-root user (uid 1010) by default
- ✅ Read-only system files
- ✅ No access to host files outside project
- ✅ Isolated credential storage
- ✅ Health checks implemented

### Permission System
- ✅ Granular command permissions
- ✅ Dangerous commands blocked (rm -rf, dd, mkfs)
- ✅ Git push disabled by default
- ✅ Pre-approved safe operations only

### Docker Images
- ✅ Regular security updates
- ✅ Minimal attack surface
- ✅ Trivy security scanning in CI
- ✅ Multi-platform builds (amd64, arm64)

### Supply Chain
- ✅ Dependency pinning
- ✅ Verified base images
- ✅ Automated vulnerability scanning
- ✅ Signed releases (planned)

## Known Security Limitations

1. **Root Access Available**: User has sudo access inside container (design choice for flexibility)
2. **Network Access**: Container can access host network via localhost mapping
3. **Volume Mounting**: Projects are mounted with full read/write access
4. **Docker Socket**: Not mounted by default, but users can mount it

## Security Best Practices

### For Users

1. **Keep Updated**: Run `claude-update` regularly
2. **Review Permissions**: Check `.claude/settings.local.json`
3. **Limit Exposure**: Don't mount sensitive directories
4. **Use Volumes**: Store credentials in Docker volumes, not project
5. **Network Isolation**: Use Docker networks for sensitive services

### For Contributors

1. **No Secrets**: Never commit API keys, tokens, or credentials
2. **Validate Input**: Always sanitize user input in scripts
3. **Minimal Privileges**: Request least privileges necessary
4. **Code Review**: All PRs require review before merge
5. **Test Security**: Run `make ci` before submitting

## Security Contact

For urgent security issues, contact: security@example.com

For non-urgent security questions, open a [Discussion](https://github.com/andreashurst/claude-docker/discussions).

## Acknowledgments

We appreciate security researchers who report vulnerabilities responsibly. Contributors will be:

- Listed in release notes (with permission)
- Credited in CHANGELOG.md
- Thanked publicly (unless they prefer anonymity)

## Additional Resources

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

---

Thank you for helping keep Claude Docker secure! 🔒
