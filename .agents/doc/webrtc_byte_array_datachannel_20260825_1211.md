# WebRTC DataChannel Byte Array Send & Receive Feature

## Overview

Added binary byte array (`Uint8List`) sending controls, hex presets menu, and incoming binary message logging to [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart).

## Changes Implemented

### 1. Byte Array Parsing & Sending (`_sendByteArray`, `_parseByteArray`)

- Added `_parseByteArray(String raw)` supporting flexible byte input formats:
  - Hex bytes with/without prefix: `01 02 AA FF`, `0x01, 0x02, 0xAA, 0xFF`, `\x01\x02\xaa\xff`.
  - Continuous hex strings: `0102AAFF00`.
  - Comma-separated decimal values: `1, 2, 170, 255`.
- Added `_sendByteArray([Uint8List? directBytes])` utilizing `RTCDataChannelMessage.fromBinary(bytes)`:
  - Validates SCTP DataChannel state (`RTCDataChannelState.RTCDataChannelOpen`).
  - Formats sent bytes in Hex and logs to both debug console (`debugPrint`) and session event log.

### 2. Binary Message Reception & Printing

- Updated `channel.onMessage` in `_setupDataChannel` to check `data.isBinary`:
  - When binary data is received:
    - Extracts `data.binary` (`Uint8List`).
    - Formats bytes into Hex representation (`_formatBytesHex`) and printable ASCII preview (`_toPrintableAscii`).
    - Outputs to debug console:
      ```text
      [WebRTC DataChannel Received Binary] [datachannel] (8 bytes): AA BB CC DD EE FF 00 11 | ASCII: "........"
      ```
    - Appends event to in-panel session logs.
  - When text data is received:
    - Outputs string content to debug console and session log.

### 3. DataChannel UI Controls & Presets Menu

In Card 4 (DataChannel Control & Session Logs):

- **Text Message Input Row**: Dedicated string input with "Send Text" button.
- **Byte Array Input Row**: Dedicated hex/byte input with "Send Byte Array" button.
- **Byte Presets Menu (`PopupMenuButton`)**:
  - `Ping Packet: 01 00 00 00` (4 bytes)
  - `Sync Header: AA BB CC DD EE FF 00 11` (8 bytes)
  - `Sequential 16-Bytes: 00..0F`
  - `Bit Patterns: FF/55/AA/00` (16 bytes)
  - `ASCII "Hello WebRTC!" in Hex` (13 bytes)

## Verification Results

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> No issues found (0 errors, 0 warnings).
- `flutter test` -> All tests passed.
