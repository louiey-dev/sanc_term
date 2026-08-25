# WebRTC DataChannel Byte Array Framing Fix

## Root Cause Analysis

When sending `AA BB CC DD EE FF 00 11` (8 bytes), the device received 12 bytes (`00 00 00 08 AA BB CC DD EE FF 00 11`):

1. **Why `00 00 00 08` was prepended**:
   - The Binary Header Protocol previously packed 5 header bytes: `[0x01]` (Command Type) + `[0x00, 0x00, 0x00, 0x08]` (32-bit big-endian payload length: 8) + 8 data bytes = 13 total bytes.
2. **Why the device logged 12 bytes**:
   - The embedded device's WebRTC message handler parsed Byte 0 (`0x01`) as the command ID, and treated everything after Byte 0 (`data + 1`, size: 12 bytes) as the raw payload without expecting the 4-byte length prefix.
   - Because WebRTC SCTP packets are message-oriented, the packet size is already provided at the transport layer, making an extra 4-byte length field redundant for single byte array packets.

## Solution

In [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart):

1. **Direct 1-Byte Command Envelope (`_sendByteArray`)**:
   - Packets are now sent as `[0x01, ...rawBytes]` (9 bytes total for 8 payload bytes).
   - When the device strips Byte 0 (`0x01`), it receives exactly `AA BB CC DD EE FF 00 11` (8 bytes).
2. **Raw Unframed Mode**:
   - If **Binary Header Protocol** toggle is turned OFF in Card 4, it sends purely `AA BB CC DD EE FF 00 11` (8 bytes) with no prefix at all.
3. **Adaptive Receiver (`channel.onMessage`)**:
   - Dynamically supports both 1-byte command framing (`[0x01, payload]`) and 5-byte length-prefixed framing.

## Verification

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> 0 errors, 0 warnings.
- `flutter test` -> All tests passed.
