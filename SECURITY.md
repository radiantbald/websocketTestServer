# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Features

This WebSocket test server includes the following security measures:

### ✅ Implemented Security Features

1. **CORS Protection**
   - Restricted to localhost and specific development domains
   - Origin validation for WebSocket connections
   - Logging of rejected connections

2. **Input Validation**
   - Username validation (max 50 characters, sanitized)
   - Message content validation (max 1024 characters)
   - HTML tag removal from messages
   - Special character filtering

3. **Rate Limiting & Capacity**
   - Maximum 100 concurrent connections
   - Connection rejection when at capacity
   - Message size limits

4. **Error Handling**
   - Graceful error responses
   - Detailed logging for security events
   - Connection cleanup on errors

### ⚠️ Security Considerations for Production

**This is a TEST SERVER. For production use, implement additional security measures:**

1. **Authentication & Authorization**
   ```go
   // TODO: Add JWT or session-based authentication
   // TODO: Implement user roles and permissions
   ```

2. **HTTPS/WSS**
   ```go
   // TODO: Use WSS (WebSocket Secure) in production
   // TODO: Implement SSL/TLS certificates
   ```

3. **Rate Limiting**
   ```go
   // TODO: Implement per-user rate limiting
   // TODO: Add DDoS protection
   ```

4. **CORS Configuration**
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
   
   // TODO: For production, replace with your actual domains
   // allowedOrigins := []string{
   //     "https://yourdomain.com",
   //     "https://www.yourdomain.com",
   // }
   ```

5. **Additional Security Headers**
   ```go
   // TODO: Add security headers
   w.Header().Set("X-Content-Type-Options", "nosniff")
   w.Header().Set("X-Frame-Options", "DENY")
   w.Header().Set("X-XSS-Protection", "1; mode=block")
   ```

6. **Database Security**
   ```go
   // TODO: If using database, implement:
   // - SQL injection prevention
   // - Connection encryption
   // - Access controls
   ```

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **DO NOT** create a public GitHub issue
2. Email security concerns to: [your-email@domain.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Best Practices

### For Developers

1. **Never commit secrets** (API keys, passwords, tokens)
2. **Use environment variables** for configuration
3. **Keep dependencies updated** regularly
4. **Run security scans** before deployment
5. **Implement proper logging** for security events

### For Deployment

1. **Use HTTPS/WSS** in production
2. **Configure proper CORS** for your domains
3. **Implement authentication** before going live
4. **Set up monitoring** and alerting
5. **Regular security audits**

## Security Tools Used

- `govulncheck` - Vulnerability scanning
- `staticcheck` - Static analysis
- `go vet` - Code analysis

## Regular Security Tasks

- [ ] Update dependencies monthly
- [ ] Run security scans before releases
- [ ] Review and update CORS settings
- [ ] Monitor logs for suspicious activity
- [ ] Test authentication mechanisms

---

**Remember**: This is a test server for development and learning purposes. Always implement additional security measures before using in production environments.
