# WebRTC DataChannel File Open & Send Feature

## Overview

Added native file picking, binary chunked streaming, and transmission menu controls over WebRTC SCTP DataChannel in [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart).

## Changes Implemented

### 1. File Selection & Inspection (`_pickFile`)

- Integrates `FilePicker.pickFiles()` to select arbitrary binary or text files from the host filesystem.
- Displays the selected filename and formatted file size in the DataChannel controls area.
- Supports loading file byte content directly into the Hex Byte Array editor field for inspection before transmission.

### 2. Chunked & Single-Payload File Transmission (`_sendFile`)

- Reads file binary bytes (`Uint8List`).
- Supports chunked streaming mode (default 16 KB or 64 KB slices) to respect SCTP maximum transmission unit (MTU) boundaries and avoid congestion.
- Incorporates pacing delay between bursts (`Future.delayed(const Duration(milliseconds: 15))`) every 64 KB.
- Displays real-time progress bar (`LinearProgressIndicator`) with percentage completion.
- Outputs detailed metrics to the debug console (`debugPrint`) and session log:
  ```text
  [WebRTC DataChannel] Sent File "firmware.bin" (262144 bytes in 16 chunks, chunk size: 16384 bytes, header sample: 7F 45 4C 46 ...)
  ```

### 3. File Transfer UI & Popup Menu

In Card 4 (DataChannel Control & Session Logs):

- **Selected File Field**: Shows file name and size with clear status.
- **Open File Button**: Launches the system file dialog.
- **Send File Button**: Initiates chunked binary transmission.
- **File Menu (`PopupMenuButton`)**:
  - `Send Chunked (16 KB Chunks - Recommended)`
  - `Send Chunked (64 KB Chunks)`
  - `Send as Single Binary Message`
  - `Open File & Load into Hex Field`

## Verification Results

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> No issues found (0 errors, 0 warnings).
- `flutter test` -> All tests passed.
