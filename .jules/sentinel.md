# Sentinel Journal

## 2026-10-26 - Insecure badCertificateCallback in HttpClient
**Vulnerability:** `badCertificateCallback` in `ApiClient` unconditionally accepted invalid/self-signed TLS certificates for all domains when running in debug mode, and bypassed certificate verification for any `10.x` and `192.168.x` IP address even in release/production builds.
**Learning:** Supporting local development against self-signed HTTPS endpoints (e.g., Laravel Herd `.test` domains or local machine IP addresses) led to blanket trust in debug mode and leaky subnet checks in release mode, exposing production network traffic to Man-in-the-Middle (MitM) attacks.
**Prevention:** In release mode (`!kDebugMode`), `badCertificateCallback` must strictly return `false` without exception. In debug mode, invalid/self-signed certificate acceptance must be explicitly restricted to recognized local development hosts (`localhost`, `127.0.0.1`, `10.0.2.2`, `.test`, and local LAN subnets) rather than returning `true` for all remote domains.
