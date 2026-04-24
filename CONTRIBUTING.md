# Contributing

Thanks for your interest in improving FloatingPermissions.

## Development Setup

1. Clone the repository.
2. Open `Package.swift` in Xcode, or work from the command line.
3. Run the test suite:

   ```sh
   swift test
   ```

4. To validate the demo app, open `Example/Example.xcodeproj` and run the
   `Example` scheme.

## Pull Requests

- Keep changes focused and easy to review.
- Follow the existing Swift style.
- Add or update tests when behavior changes.
- Update `README.md` when public API, supported permissions, or behavior changes.
- Keep user-facing package strings in English.
- Do not add localization infrastructure unless the maintainers agree to it first.

## Adding Permissions

FloatingPermissions currently supports Accessibility and Input Monitoring. New
permission panes should keep the existing modular shape:

- Add a `FloatingPermissionPane` case.
- Add or reuse a `PrivacySecurityAnchor`.
- Add a `PermissionStatusProviding` implementation when status can be checked reliably.
- Register the provider in `PermissionStatusRegistry`.
- Update tests, README, and the example app.

## Reporting Bugs

Please include:

- macOS version.
- Xcode or Swift toolchain version.
- Whether the issue happens in the example app.
- Steps to reproduce.
- Any relevant screenshots or screen recordings.

Do not include private app signing identities, provisioning profiles, or user
data in issues.
