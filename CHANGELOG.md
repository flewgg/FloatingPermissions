# Changelog

All notable changes to FloatingPermissions will be documented in this file.

## Unreleased

- Added Permiso-style floating guide panel.
- Added PermissionFlow-style close and Settings header controls.
- Added System Settings window stabilization before showing the guide.
- Added permission-resolution polling so the guide closes when permission is granted.
- Added public open-source documentation.

## 0.1.1

- Added permission status helpers:
  - `FloatingPermissionPane.accessibility.isGranted`
  - `FloatingPermissionPane.inputMonitoring.isGranted`
- Added status provider registry for supported panes.

## 0.1.0

- Initial Swift package release.
- Added Accessibility and Input Monitoring pane support.
- Added SwiftUI button and controller APIs.
- Added example app and package tests.
