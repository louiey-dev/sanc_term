# WebRTC Periodic Packet Statistics Logging (1-Minute Interval)

## Overview

Added periodic 1-minute audio and video packet statistics logging to the debug console window via `debugPrint` and session log in [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart).

## Changes Implemented

### 1. Stats State Management

In `_CmWebRtcPanelState`, added tracking variables for periodic 1-minute polling:

- `Timer? _statsTimer`: Periodic timer triggering every 60 seconds (`const Duration(minutes: 1)`).
- `int _prevAudioPackets`, `int _prevVideoPackets`: Cumulative packet counters from the previous interval used to calculate deltas.
- `int _prevAudioBytes`, `int _prevVideoBytes`: Cumulative byte counters for calculating bandwidth throughput.
- `bool _hasRecordedInitialStats`: Flag indicating whether a baseline report has been established.

### 2. Stats Parsing & Console Output

Added `_logWebRtcPacketStats()` to query `_peerConnection.getStats()`:

- Parses both W3C standard (`inbound-rtp`) and legacy/libwebrtc (`ssrc`) statistics reports.
- Extracts `packetsReceived`, `bytesReceived`, `packetsLost`, and `framesDecoded` / `framesReceived` separated by media kind (`audio` vs `video`).
- Computes 1-minute deltas for incoming audio and video packet counts and data volumes.
- Outputs detailed formatted metrics to the debug console window via `debugPrint`:
  ```text
  [2026-08-25 11:20:00] [WebRTC 1-min Stats] Packets Received -> Audio: 3600 pkts (+600/min, 96.0 KB/min, lost: 0) | Video: 1800 pkts (+300/min, 1.45 MB/min, decoded: 1800, lost: 0)
  ```
- Appends concise packet summaries to the in-panel session logs.

### 3. Lifecycle Integration

- **Start**: Automatically starts when `_createPeerConnection()` initializes a connection.
- **Stop**: Automatically cancels the timer and resets counter deltas in `_disconnect()` and `dispose()`.

## Verification Results

- Ran `dart analyze lib/features/panels/common/cm_webrtc.dart` -> No issues found.
- Ran `flutter test` -> All tests passed.
