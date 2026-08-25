# WebRTC DataChannel Auto-Recovery & Resilient Reopen

## Why `RTCDataChannelClosed` Happened

When sending a file via WebRTC SCTP DataChannel:

1. **Remote Peer Closure**:
   - Many embedded WebRTC / libdatachannel file receiver examples automatically call `dc->close()` upon receiving the file completion EOF packet (`0x04`).
   - If the remote device firmware crashed or did not implement file metadata handling, it reset the SCTP association.
2. **SCTP Buffer Reset**:
   - Sending high-frequency bursts without pacing delay can saturate the SCTP buffer, prompting the underlying WebRTC stack to close the channel with a stream reset.
3. **No Automatic Recovery**:
   - Once closed, subsequent send attempts failed because the panel held the stale reference to the closed channel without re-opening it.

## Improvements Implemented

In [`cm_webrtc.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart):

1. **Automatic DataChannel Re-Creation (`_reopenDataChannel`)**:
   - When any send action (`_sendByteArray`, `_sendFile`, `_sendDataMessage`) detects a closed DataChannel while `PeerConnection` is active, it automatically calls `_reopenDataChannel()` to negotiate and restore the channel.
2. **Smoothed Chunk Transmission Pacing**:
   - Updated `_sendFile` with a 10ms pacing delay per chunk to keep SCTP throughput steady (~1.6 MB/s) without buffer congestion.
3. **UI Status Badge & Manual Reopen Button**:
   - Added a live status badge (`DataChannel: open` / `DataChannel: closed`) and a **Reopen Channel** button in Card 4 for quick recovery.

## Verification

- `dart analyze lib/features/panels/common/cm_webrtc.dart` -> 0 issues found.
- `flutter test` -> All tests passed.
