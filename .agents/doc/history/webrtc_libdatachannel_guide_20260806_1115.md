# WebRTC & libdatachannel Testing & Configuration Guide

This guide explains how `libdatachannel`'s `./offerer` and `./client` CLI examples operate and how to connect to them via `sanc_term`'s `CmWebRtcPanel` (`cm_webrtc`).

---

## Mode 1: Connecting to `libdatachannel` `./offerer` (Manual SDP Mode)

### Workflow

```
[ sanc_term (cm_webrtc) ]                           [ ./offerer CLI Terminal ]
            |                                                     |
  Paste Offer in Step 1                                           |
            |                                                     |
  Click "Parse Offer & Create Answer"                             |
            |                                                     |
  Copy Step 3 (Answer SDP + Embedded Candidates) ------------> Press '1'
                                                            Paste Step 3 & Press Enter
                                                                  |
  [ State: CONNECTED ] <===================================> [ State: connected ]
                                                             [ Data channel "datachannel": open ]
```

---

## Mode 2: Connecting via `signaling-server.py` (`./client`)

In `libdatachannel`'s `./client` example, **each client gets assigned a random 4-character ID** (e.g. `qaBt`) by the program upon connecting to `signaling-server.py`.

### 1. Run `signaling-server.py`

```bash
python3 signaling-server-python/signaling-server.py 0.0.0.0:8000
```

### 2. Run `./client` on Orin

```bash
./client ws://<signaling_server_ip>:8000
```
- `signaling-server.py` prints: `Client qaBt connected`.
- Orin terminal prints: `The local ID is qaBt`.

### 3. Connect `sanc_term`

In `sanc_term` (`cm_webrtc`):
- **Signaling Mode**: `WebSocket Server`
- **WS Signaling URL**: `ws://<signaling_server_ip>:8000`
- **Peer ID**: `sanc_term`
- **Room ID / Target Peer**: **`qaBt`** (Enter the 4-char ID printed by Orin!)
- Click **Connect WS**.
- `signaling-server.py` prints: `Client sanc_term connected`.

### 4. Send Offer from Orin `./client`

In Orin `./client` terminal:
```text
Enter a remote ID to send an offer:
```
Type **`sanc_term`** and press **Enter**.
The signaling server routes the SDP offer/answer automatically and WebRTC DataChannel connects!
