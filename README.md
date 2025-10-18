# Get-OIDCToken
A PowerShell script to obtain an OpenID Connect (OIDC) access token from an identity provider using the OAuth 2.0 authorization code or client credentials flow.

---

## 🚀 Features

- Supports OAuth 2.0 flows:
  - Client Credentials (machine-to-machine)
  - Authorization Code (interactive)
- Works with ADFS, Azure AD, and other OIDC-compliant providers
- Outputs the access token or ID token

---

## 📥 Requirements

- PowerShell 5.1+ or PowerShell Core (7+)
- Internet access to reach the identity provider
- Registered OAuth application
- Parse-JWTtoken https://github.com/alex203/Parse-JWTtoken.git

---

## 🛠 Usage

### Basic Example

```powershell
.\Get-OidcToken.ps1 -clientId "your-client-id" `
                    -redirectURI "your-redirectURI"
                    -scope "openid profile email" `
