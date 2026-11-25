# Tournament Management TestFlight build

`.github/workflows/ios-testflight.yml` builds the iPhone simulator app on every pull request and push to `main`. On a push to `main`, it also archives and uploads an IPA to TestFlight.

Add these GitHub Actions secrets to **MrrTools/tournaments_diplomka** (repository Settings → Secrets and variables → Actions). Secrets in `Elysium-a-s` cannot be shared with this repository because it has a different owner.

| Secret | Value |
| --- | --- |
| `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64` | Base64 encoded Apple Distribution `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password of the `.p12` file |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64 encoded App Store provisioning profile for `saro.tournamentsManagement` and team `57VY4JK4N8` |
| `ASC_API_KEY_ID` | App Store Connect API key ID |
| `ASC_API_ISSUER_ID` | App Store Connect issuer ID |
| `ASC_API_PRIVATE_KEY` | Contents of the matching `.p8` key |

The bundle ID must already exist in App Store Connect. The profile must match the distribution certificate and bundle ID. The workflow fails at the signing check if a secret is missing; it does not print secret values. Archive build numbers use the GitHub run number plus 1000 to avoid reusing build 1 from earlier local builds.
