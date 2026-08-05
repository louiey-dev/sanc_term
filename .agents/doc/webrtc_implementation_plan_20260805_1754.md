# WebRTC Architecture & Implementation Plan (`cm_webrtc`)

This document outlines the architecture, design, and implementation plan for integrating WebRTC (`flutter_webrtc`) into `sanc_term` for live video streaming and P2P DataChannel communication with embedded devices running `libdatachannel` (C++).

## Purpose & Overview

The goal is to provide a production-ready WebRTC panel (`cm_webrtc`) under the `COMMON` group in `sanc_term`. The panel connects to embedded systems (e.g. NVIDIA Jetson, Rockchip, Linux) using WebRTC DataChannel for terminal/telemetry commands and WebRTC Video Track for camera streaming.

---

## Key Architecture & Design Decisions

### 1. Panel Placement & Registration

- **Group:** `COMMON` section in `lib/features/panels/panel_registry.dart`.
- **Panel ID:** `cm_webrtc`.
- **Widget:** `CmWebRtcPanel` in `lib/features/panels/common/cm_webrtc.dart`.

### 2. Riverpod Parameter State Persistence

To ensure that parameters are retained during frequent navigation between panels, parameters are stored in `cmWebRtcParamsProvider` (`StateProvider<CmWebRtcParamsState>`):

- Signaling WebSocket URL (`ws://...`)
- Room ID & Target Peer ID
- STUN Server URL
- Video & Audio track toggles
- Preferred Codec (`H264`, `VP8`, `VP9`)
- WebRTC DataChannel toggle & test message state

---

## Code Structure

### 1. Panel Registry (`lib/features/panels/panel_registry.dart`)

```dart
PanelEntry(
  id: 'cm_webrtc',
  label: 'WebRTC',
  description: 'WebRTC stream & P2P DataChannel',
  icon: Icons.video_call,
),
```

### 2. WebRTC Panel (`lib/features/panels/common/cm_webrtc.dart`)

Modular UI divided into three sub-cards:

1. **Signaling & Peer Configuration**
2. **Live Camera Viewport & Controls**
3. **DataChannel & Control Overlay**

---

## Verification Strategy

- Run `flutter pub get` to resolve `flutter_webrtc`.
- Run `flutter analyze` to verify clean compilation with zero warnings.
- Test panel state retention when switching between `WebRTC`, `Cmd History`, and `General Settings`.
