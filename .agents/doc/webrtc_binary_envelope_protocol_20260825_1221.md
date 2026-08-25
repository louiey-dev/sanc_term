# WebRTC Binary Header Envelope Protocol (Array vs File Framing)

## Overview

Applied the **Option A: Binary Header Protocol** to distinguish generic raw byte arrays from structured binary file transfers over WebRTC SCTP DataChannels in [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart).

## Protocol Specification

| Type (`Byte 0`) | Name | Structure & Metadata |
| :--- | :--- | :--- |
| `0x01` | **Raw Byte Array / Sensor Data** | `[0x01]` + `Length (4B Big-Endian)` + `Payload (NB)` |
| `0x02` | **File Transfer Start (Metadata)** | `[0x02]` + `NameLen (1B)` + `Filename (NB UTF-8)` + `FileSize (4B Big-Endian)` + `TotalChunks (2B Big-Endian)` |
| `0x03` | **File Chunk Payload** | `[0x03]` + `ChunkIndex (2B Big-Endian)` + `ChunkLen (2B Big-Endian)` + `ChunkData (NB)` |
| `0x04` | **File Transfer Complete** | `[0x04]` + `TotalChunks (2B Big-Endian)` + `TotalBytes (4B Big-Endian)` |

## Features & Implementation

### 1. Transmission (`_sendByteArray` & `_sendFile`)

- When **Binary Header Protocol** is enabled (default `true`):
  - **Byte Array**: Wrapped with `0x01` and 4-byte payload length before sending.
  - **File**: Transmits `0x02` start envelope with filename and chunk metrics, streams `0x03` chunk envelopes, and concludes with `0x04` completion envelope.
- When toggled off: Sends raw, unframed binary packets for legacy or raw device compatibility.

### 2. Reception & Automatic Recognition (`channel.onMessage`)

- Inspects incoming binary messages for `0x01`, `0x02`, `0x03`, and `0x04` command types.
- Decodes metadata and prints structured logs:
  - `0x01`: `[WebRTC DataChannel Received Framed Array [0x01]] [datachannel] (Length: X bytes): <Hex>`
  - `0x02`: `[WebRTC DataChannel File Start [0x02]] Filename: "...", Size: X bytes, Total Chunks: Y`
  - `0x03`: `[WebRTC DataChannel File Chunk [0x03]] Chunk #i (X bytes received)`
  - `0x04`: `[WebRTC DataChannel File Complete [0x04]] Finished transfer of X bytes (Y chunks).`
  - **Fallback**: Automatically falls back to printing generic raw binary if the packet does not match the header envelope format.

### 3. UI Controls & Persistence

- Added **Binary Header Protocol (Envelope: 0x01 Array / 0x02 File)** switch tile in Card 4.
- Persisted to Hive `app_settings` under `webrtc_binary_envelope`.

## Verification Results

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> No issues found (0 errors, 0 warnings).
- `flutter test` -> All tests passed.
