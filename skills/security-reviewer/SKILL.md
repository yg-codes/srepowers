---
name: security-reviewer
description: Use when conducting security audits, reviewing code for vulnerabilities, or analyzing infrastructure security. Invoke for SAST scans, penetration testing, DevSecOps practices, cloud security reviews.
---

# Security Reviewer

## When to Use This Skill

- Code review and SAST scanning
- Vulnerability scanning and dependency audits
- Secrets scanning and credential detection
- Penetration testing and reconnaissance
- Infrastructure and cloud security audits
- DevSecOps pipelines and compliance automation

## Core Workflow

1. **Scope** - Map attack surface and critical paths
2. **Scan** - Run SAST, dependency, and secrets tools
3. **Review** - Manual review of auth, input handling, crypto
4. **Test and classify** - Validate findings, rate severity (Critical/High/Medium/Low)
5. **Report** - Document findings with remediation guidance

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| SAST Tools | `references/sast-tools.md` | Running automated scans |
| Vulnerability Patterns | `references/vulnerability-patterns.md` | SQL injection, XSS, manual review |
| Secret Scanning | `references/secret-scanning.md` | Gitleaks, finding hardcoded secrets |
| Penetration Testing | `references/penetration-testing.md` | Active testing, reconnaissance, exploitation |
| Infrastructure Security | `references/infrastructure-security.md` | DevSecOps, cloud security, compliance |
| Report Template | `references/report-template.md` | Writing security report |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "This is internal, security is less critical" | Internal systems get compromised. Apply defense in depth. |
| "The framework handles security" | Verify framework defaults. Misconfigurations are vulnerabilities. |
| "Low-severity finding, skip it" | Low-severity findings chain into critical exploits. |
| "No sensitive data in this service" | Audit data flows. Services often handle more data than assumed. |
| "Pentest isn't needed yet" | Security review at every major change. Don't wait for pentests. |
| "Compliance is handled separately" | Security and compliance overlap. Review together. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

1. Executive summary with risk assessment
2. Findings table with severity counts
3. Detailed findings with location, impact, and remediation
4. Prioritized recommendations

## Knowledge Reference

OWASP Top 10, CWE, Semgrep, Bandit, ESLint Security, gosec, npm audit, gitleaks, trufflehog, CVSS scoring, nmap, Burp Suite, sqlmap, Trivy, Checkov, HashiCorp Vault, AWS Security Hub, CIS benchmarks, SOC2, ISO27001