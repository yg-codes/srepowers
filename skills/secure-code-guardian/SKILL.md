---
name: secure-code-guardian
description: Use when implementing authentication/authorization, securing user input, or preventing OWASP Top 10 vulnerabilities. Invoke for authentication, authorization, input validation, encryption, OWASP Top 10 prevention.
---

# Secure Code Guardian

## When to Use This Skill

- Implementing authentication/authorization
- Securing user input handling
- Implementing encryption
- Preventing OWASP Top 10 vulnerabilities
- Security hardening existing code
- Implementing secure session management

## Core Workflow

1. **Threat model** - Identify attack surface and threats
2. **Design** - Plan security controls
3. **Implement** - Write secure code with defense in depth
4. **Validate** - Test security controls
5. **Document** - Record security decisions

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| OWASP | `references/owasp-prevention.md` | OWASP Top 10 patterns |
| Authentication | `references/authentication.md` | Password hashing, JWT |
| Input Validation | `references/input-validation.md` | Zod, SQL injection |
| XSS/CSRF | `references/xss-csrf.md` | XSS prevention, CSRF |
| Headers | `references/security-headers.md` | Helmet, rate limiting |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Input validation can wait" | Validate at every boundary. Injection attacks exploit gaps. |
| "This endpoint doesn't need auth" | Authenticate everything. Unauthenticated endpoints get found. |
| "Hardcoded secret is fine in dev" | No secrets in code, ever. Use secret managers from day one. |
| "This dependency is trusted" | Verify all dependencies. Supply chain attacks are real. |
| "HTTPS isn't needed internally" | Encrypt in transit everywhere. Zero trust networking. |
| "Sanitization is overkill for admin pages" | Sanitize all input. Admin pages are high-value targets. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing security features, provide:
1. Secure implementation code
2. Security considerations noted
3. Configuration requirements (env vars, headers)
4. Testing recommendations

## Knowledge Reference

OWASP Top 10, bcrypt/argon2, JWT, OAuth 2.0, OIDC, CSP, CORS, rate limiting, input validation, output encoding, encryption (AES, RSA), TLS, security headers

## Resources

### Style Guides

Google Style Guides index covers multiple languages with security-conscious conventions:

- Google Style Guides: https://google.github.io/styleguide/

### Security References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- CWE/SANS Top 25: https://cwe.mitre.org/top25/