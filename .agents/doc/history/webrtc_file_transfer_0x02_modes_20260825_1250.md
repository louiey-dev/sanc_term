# WebRTC File Transfer 0x02 Direct Delivery Modes

## Why the Warning Occurred

When transmitting a file across chunks, the previous multi-phase routine sent:

1. `0x02`: File metadata packet (filename, size) -> Accepted by device (type `0x02` recognized).
2. `0x03`: File chunk packets -> Warning on device: `[WebRTC Warning] Received unknown binary message type: 0x03`.
3. `0x04`: File completion packet -> Warning on device: `[WebRTC Warning] Received unknown binary message type: 0x04`.

**Root Cause**: The embedded device firmware only defines binary command handlers for `0x01` (Byte Array) and `0x02` (File Transfer). It does not implement `0x03` (Chunk) or `0x04` (End), so all chunk payloads under `0x03` were ignored by the device.

## Solution

In [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart):

1. **Default `[0x02 + Filename + Data]` Single-Payload Delivery**:
   - The default "Send File" action transmits the entire file encapsulated with `0x02` and filename metadata in one shot:
     `[0x02]` + `NameLen (1B)` + `Filename (NB)` + `File Content (All Bytes)`
   - The device receives `0x02`, extracts the filename and entire file content, and writes the file to disk successfully without warnings.
2. **Additional Delivery Modes in File Menu**:
   - **Send `[0x02 + Filename + Data]`**: Recommended for embedded device file saving.
   - **Send `[0x02 + Data]`**: Sends single payload with `0x02` prefix only.
   - **Send Raw Binary File**: Sends pure binary payload with no prefix.
   - **Send Chunked (0x02 Header)**: Slices large files into chunks where each chunk is prefixed by `0x02`.
   - **Send Multi-Phase (`0x02` / `0x03` / `0x04`)**: Legacy 3-phase protocol.

## Verification

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> 0 issues found.
- `flutter test` -> All tests passed.
