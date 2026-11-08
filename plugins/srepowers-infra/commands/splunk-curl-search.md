---
description: "Run bounded, read-only SPL searches against any Splunk Enterprise instance over curl (REST) from a client machine — no SSH to the Splunk host, no extra CLI. Use for \"is host X logging to Splunk\", \"list senders\", \"when did host Y stop\", index retention/size, sourcetype breakdowns, or any ad-hoc SPL. Detects the front door first (Google oauth2-proxy, Splunk-native SAML/Microsoft Entra, filtered :8089) and picks the auth path; credentials from 1Password (op://) or a 0600 KEY=VALUE file; SPL is linted to block mutating, all-time raw, index=* raw, and leading-wildcard searches."
---
Invoke the srepowers-infra:splunk-curl-search skill and follow it exactly as presented to you
