# FloodGuard Mobile

Flutter mobile client for FloodGuard community monitoring and barangay response.

## User flows

- Public: use the FloodGuard website for live monitoring without signing in.
- Resident: account registration, password recovery, dashboard monitoring, community posts, incident reports, alerts, and live response tracking.
- Responder: assignment dashboard, response status updates, live location, and completion notes.

Community posts are reviewed for public publication. Incident reports remain in the private barangay response workflow.

The mobile app intentionally has no guest monitoring entry. Residents see station readings after signing in; public viewing remains on the website.

Resident registration includes explicit consent for FloodGuard safety notifications. Live-location consent remains separate and is requested only for an active response.

Registration also requires a clear valid-ID or proof-of-residency image. After the form is submitted, the app opens a verification popup where the resident enters the six-digit code sent by email and taps **Verify**. The popup can resend the code. Successful verification completes registration and places the application in the administrator review queue. A verified email does not activate the account by itself: an administrator must still review and approve the application.

Resident password recovery uses three separate screens: enter the account email, enter and verify the six-digit email code, and then create a new password. The code expires after 15 minutes. Approval sends an email confirmation, while rejection emails the administrator-entered reason.

The reset code is never returned to or automatically filled by the mobile app, including in development. Residents must read it from their email. The resident dashboard shows whether the bridge is open or closed instead of exposing station battery percentage.

Authenticated resident and responder dashboards cannot return to the public landing page with Android Back. Users leave the authenticated area only through the logout action, which asks for confirmation and clears the navigation history.

Resident registration validates a real email-shaped address and Philippine mobile numbers in either `09XXXXXXXXX` or `+639XXXXXXXXX` format. The backend saves mobile numbers as `+639XXXXXXXXX` and normalizes names and addresses to proper case.

## Run on the Android emulator

```powershell
Set-Location "C:\Development\projects\floodguard_mobile"
flutter pub get
flutter emulators --launch Pixel_7
flutter run -d emulator-5554
```

The Android emulator connects to the local XAMPP API through `http://10.0.2.2/floodguard`.

## Quality checks

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```
