# Security Workflows Guide

This document explains the security workflows and tools integrated into this project for automated security scanning, vulnerability detection, and automatic patching.

## 🚀 Overview

The project includes several GitHub Actions workflows that provide comprehensive security coverage:

1. **Automated Security Scan** - Runs on every push/PR
2. **Manual Security Scan** - On-demand scanning for specific images
3. **Dependency Security Scan** - Scans Go and NPM dependencies
4. **Auto-Patching with Copa** - Automatically patches vulnerabilities

## 🔧 Workflows

### 1. Automated Security Scan (`security-scan.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Weekly scheduled runs (Sundays at 2 AM UTC)

**What it does:**
- Builds Docker image from `external/gateway/Dockerfile`
- Generates SBOM using Syft
- Scans for vulnerabilities using Grype
- Automatically patches critical/high severity issues with Copa
- Creates patched Docker images
- Provides comprehensive security reporting

**Outputs:**
- SBOM in SPDX format
- Vulnerability reports in JSON
- Patched Docker images
- Security summaries in PR comments

### 2. Manual Security Scan (`manual-security-scan.yml`)

**Triggers:**
- Manual workflow dispatch
- Customizable scan parameters

**Inputs:**
- `image_tag`: Docker image tag to scan (default: `latest`)
- `scan_type`: Type of scan (`full`, `quick`, `vuln-only`)
- `fail_on`: Severity threshold for workflow failure

**Use cases:**
- Security audits of specific image versions
- Pre-deployment security checks
- Compliance scanning
- Incident response

### 3. Dependency Security Scan (`dependency-scan.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Daily scheduled runs (6 AM UTC)

**Go Dependencies:**
- `govulncheck`: Scans for known Go vulnerabilities
- `gosec`: Security linter for Go code
- `staticcheck`: Static analysis for Go code

**NPM Dependencies:**
- `npm audit`: Scans for known NPM vulnerabilities
- Supports multiple `package.json` files in the repository

## 🛠️ Tools Used

### Syft
- **Purpose**: Software Bill of Materials (SBOM) generation
- **Output**: SPDX format for comprehensive dependency tracking
- **Integration**: Automatically runs on every build

### Grype
- **Purpose**: Container image vulnerability scanning
- **Coverage**: OS packages, language-specific packages, application dependencies
- **Severity Levels**: Critical, High, Medium, Low
- **Integration**: Runs after every Docker build

### Copa
- **Purpose**: Automatic vulnerability patching
- **Strategy**: Minimal patching approach
- **Coverage**: OS packages, language packages
- **Integration**: Automatically patches critical/high severity issues

### Go Security Tools
- **govulncheck**: Official Go vulnerability database scanning
- **gosec**: Security-focused Go linter
- **staticcheck**: Comprehensive Go static analysis

## 📋 Configuration

### Copa Configuration (`.copa/config.yaml`)

The Copa configuration file controls auto-patching behavior:

```yaml
patch:
  severity-thresholds:
    critical: true    # Auto-patch critical issues
    high: true        # Auto-patch high issues
    medium: false     # Don't auto-patch medium
    low: false        # Don't auto-patch low
  
  strategy: "minimal" # Apply minimal patches
  max-patches: 50     # Limit patches per image
```

### Security Policy (`SECURITY.md`)

Comprehensive security policy covering:
- Vulnerability response timelines
- Security contact information
- Disclosure procedures
- Compliance requirements

## 🚀 Getting Started

### 1. Enable Workflows

The workflows are automatically enabled when you push to the repository. Ensure you have:

- GitHub Actions enabled for the repository
- Appropriate permissions for the `GITHUB_TOKEN`
- Container registry access (for image building)

### 2. First Run

1. Push to `main` or `develop` branch
2. Check the Actions tab for workflow execution
3. Review generated security reports
4. Download SBOM and vulnerability artifacts

### 3. Manual Scanning

1. Go to Actions → Manual Security Scan
2. Click "Run workflow"
3. Configure scan parameters:
   - Image tag to scan
   - Scan type (full/quick/vuln-only)
   - Failure threshold
4. Click "Run workflow"

### 4. Review Results

- **PR Comments**: Automatic vulnerability summaries
- **Artifacts**: Downloadable security reports
- **Action Summary**: Workflow execution summaries
- **Security Dashboard**: Comprehensive security overview

## 📊 Understanding Results

### Vulnerability Severity

| Level | Description | Auto-Patch | Response Time |
|-------|-------------|------------|---------------|
| 🔴 Critical | Complete system compromise possible | ✅ Yes | 24 hours |
| 🟠 High | Significant security risk | ✅ Yes | 72 hours |
| 🟡 Medium | Moderate risk | ❌ No | 1 week |
| 🟢 Low | Minimal risk | ❌ No | 1 month |

### SBOM Information

The SBOM (Software Bill of Materials) provides:
- Complete dependency tree
- Package versions and sources
- License information
- Vulnerability mapping

### Patch Information

When Copa patches vulnerabilities:
- Original image is preserved
- Patched image gets `patched-{commit-sha}` tag
- Patch details are logged
- Rollback is always possible

## 🔍 Troubleshooting

### Common Issues

1. **Workflow Fails on High Severity**
   - Check vulnerability reports
   - Review Grype output
   - Consider adjusting `fail-on` threshold

2. **Copa Patch Failures**
   - Check Copa logs
   - Verify image accessibility
   - Review Copa configuration

3. **Permission Errors**
   - Verify `GITHUB_TOKEN` permissions
   - Check repository settings
   - Ensure workflow permissions are correct

### Debug Mode

Enable debug logging in Copa:
```yaml
logging:
  level: "debug"
  structured: true
```

### Manual Copa Testing

Test Copa locally:
```bash
# Install Copa
go install github.com/project-copacetic/copacetic@latest

# Run patch command
copa patch --image your-image:tag --report vulnerabilities.json --dry-run
```

## 🔒 Security Best Practices

### Development

1. **Regular Updates**: Keep dependencies updated
2. **Security Linting**: Use gosec in your IDE
3. **Vulnerability Scanning**: Run govulncheck locally
4. **Code Review**: Review security-related changes carefully

### Deployment

1. **Image Scanning**: Always scan before deployment
2. **Patch Management**: Use patched images in production
3. **Monitoring**: Monitor for new vulnerabilities
4. **Rollback Plan**: Have rollback procedures ready

### Compliance

1. **SBOM Generation**: Maintain up-to-date SBOMs
2. **Vulnerability Tracking**: Document all findings
3. **Patch Records**: Keep patch history
4. **Audit Trails**: Maintain security audit logs

## 📚 Additional Resources

- [Copa Documentation](https://github.com/project-copacetic/copacetic)
- [Syft Documentation](https://github.com/anchore/syft)
- [Grype Documentation](https://github.com/anchore/grype)
- [Go Security](https://go.dev/security/)
- [NPM Security](https://docs.npmjs.com/about-audit-reports)

## 🤝 Contributing

To improve security workflows:

1. **Report Issues**: Create security advisories for vulnerabilities
2. **Suggest Improvements**: Open issues for workflow enhancements
3. **Share Tools**: Recommend additional security tools
4. **Documentation**: Help improve this guide

## 📞 Support

For security-related questions or issues:

- **Security Issues**: Create security advisory in GitHub
- **Workflow Issues**: Open issue with `security-workflow` label
- **Emergency**: Use security contact information in `SECURITY.md`

---

*Last updated: $(date +%Y-%m-%d)*
