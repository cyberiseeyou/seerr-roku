# Privacy Policy

**Last Updated: September 13, 2026**

This Privacy Policy describes how the "SeerrRoku" application ("the App") handles your data. The App is designed as a client to interface with your own self-hosted Seerr instance (or the deprecated Jellyseerr, its predecessor).

## 1. Data Collection
**We do not collect, store, or transmit any personal information to our own servers or any third-party servers.** 

The App is entirely a local client that runs on your Roku device. The developer of this App has no access to your media, your usage habits, your server URL, or your login credentials.

## 2. Server Communication
The App communicates directly with two destinations: the Seerr/Jellyseerr server URL that you explicitly configure within the App (for all searching, requesting, and managing of media), and TMDB's public image CDN (`image.tmdb.org`), which the App queries directly to load movie/TV posters, backdrops, and cast photos. No credentials, session tokens, or personal data are ever sent to TMDB — only anonymous, unauthenticated image requests.

Additionally, depending on your server's configuration, it itself may communicate with other third-party APIs (such as TMDB's data API, Radarr, or Sonarr) to fulfill your requests.

## 3. Storage of Credentials
To keep you logged in, the App securely stores your server URL and authentication session tokens directly on your Roku device using Roku's secure registry. This data never leaves your device except to authenticate with your configured server.

## 4. Third-Party Services
The App does not integrate any third-party tracking, analytics, crash-reporting, or advertising SDKs. 

## 5. Changes to This Policy
We may update this Privacy Policy from time to time if the App's core functionality changes. However, our commitment to zero data collection will remain.

## 6. Contact Us
If you have any questions or concerns regarding this Privacy Policy, please contact the developer via the official repository or support channel where you downloaded the App.
