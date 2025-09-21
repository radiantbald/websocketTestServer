# Deployment Guide

## Pre-deployment Security Checklist

Before deploying to GitHub, ensure you have completed the following security checks:

### ✅ Security Audit Completed

- [x] **Dependency Vulnerability Scan**: No critical vulnerabilities found
- [x] **Static Code Analysis**: No issues detected by staticcheck and go vet
- [x] **CORS Configuration**: Configured for qabase.ru production domains
- [x] **Input Validation**: Username and message content validation implemented
- [x] **Rate Limiting**: Maximum 100 concurrent connections enforced
- [x] **Error Handling**: Graceful error responses and security logging
- [x] **Secret Detection**: No secrets found in codebase
- [x] **Security Documentation**: SECURITY.md created with guidelines

### 🔧 Security Improvements Implemented

1. **CORS Protection**
   ```go
   // Production domains for qabase.ru
   allowedOrigins := []string{
       "https://qabase.ru",
       "http://qabase.ru",
       "https://www.qabase.ru",
       "http://www.qabase.ru",
       // Development domains
       "http://localhost:9092",
       "http://127.0.0.1:9092",
       "http://localhost:3000",
       "http://127.0.0.1:3000",
   }
   ```

2. **Input Validation**
   - Username validation (max 50 chars, sanitized)
   - Message content validation (max 1024 chars)
   - HTML tag removal
   - Special character filtering

3. **Connection Limits**
   - Maximum 100 concurrent connections
   - Graceful rejection when at capacity

4. **Error Handling**
   - Detailed security logging
   - Graceful error responses
   - Connection cleanup on errors

## GitHub Deployment Steps

### 1. Initialize Git Repository

```bash
cd /Users/Popov.Oleg26/websocket-test-server
git init
git add .
git commit -m "Initial commit: Secure WebSocket test server"
```

### 2. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it `websocket-test-server` or similar
3. Make it public (for open source) or private (for personal use)

### 3. Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/websocket-test-server.git
git branch -M main
git push -u origin main
```

### 4. Enable Security Features

After pushing to GitHub:

1. **Enable GitHub Actions**: Go to repository Settings → Actions → General
2. **Enable Dependabot**: Go to repository Settings → Security → Dependabot alerts
3. **Enable Code Scanning**: Go to repository Settings → Security → Code scanning
4. **Review Security Tab**: Check for any security alerts

## Post-Deployment Security Monitoring

### Automated Checks

The repository includes GitHub Actions workflows that will automatically:

- **Daily Security Scans**: Run vulnerability checks every day at 2 AM UTC
- **Pull Request Security**: Scan every PR for security issues
- **Dependency Updates**: Monitor for vulnerable dependencies
- **Secret Detection**: Scan for accidentally committed secrets

### Manual Security Tasks

Perform these tasks regularly:

- [ ] **Monthly**: Review and update dependencies
- [ ] **Quarterly**: Review CORS settings for production readiness
- [ ] **As needed**: Update security documentation
- [ ] **Before production**: Implement additional security measures from SECURITY.md

## Production Deployment Considerations

⚠️ **This is a TEST SERVER**. Before using in production:

1. **Implement Authentication**
   - Add JWT or session-based authentication
   - Implement user roles and permissions

2. **Use HTTPS/WSS**
   - Deploy with SSL/TLS certificates
   - Use WSS (WebSocket Secure) instead of WS

3. **Update CORS Settings**
   ```go
   // Current production domains for qabase.ru
   allowedOrigins := []string{
       "https://qabase.ru",
       "http://qabase.ru",
       "https://www.qabase.ru",
       "http://www.qabase.ru",
       // Development domains (can be removed in production)
       "http://localhost:9092",
       "http://127.0.0.1:9092",
       "http://localhost:3000",
       "http://127.0.0.1:3000",
   }
   
   // TODO: Replace with your production domains
   // allowedOrigins := []string{
   //     "https://yourdomain.com",
   //     "https://www.yourdomain.com",
   // }
   ```

4. **Add Production Security Headers**
   ```go
   w.Header().Set("X-Content-Type-Options", "nosniff")
   w.Header().Set("X-Frame-Options", "DENY")
   w.Header().Set("X-XSS-Protection", "1; mode=block")
   ```

5. **Implement Rate Limiting**
   - Add per-user rate limiting
   - Implement DDoS protection

6. **Set up Monitoring**
   - Log security events
   - Monitor for suspicious activity
   - Set up alerts for security incidents

## Security Contact

For security issues or questions:
- Create a private security issue in the repository
- Follow the guidelines in SECURITY.md
- Do not create public issues for security concerns

---

**Remember**: Security is an ongoing process. Regularly review and update security measures as threats evolve.
