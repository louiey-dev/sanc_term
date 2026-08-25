# WebRTC Viewer Mode & Request Stream Implementation

## Overview

Added **Viewer Mode** support to the WebRTC panel (WebSocket Server tab) to support media streaming servers (such as libdatachannel, embedded board camera streamers, and media servers) where the server generates the SDP Offer and the client acts as the Answerer.

## Changes

1. **Request Stream Action**:
   - Added _requestStreamWebSocket() to dispatch a live video stream request ({"type": "request"}) over the active WebSocket signaling connection.
   - Added **Request Stream** (PanelActionButton) to the WebSocket Server toolbar when connected.

2. **Automatic SDP Offer & Answer Handling**:
   - Updated _connectWebSocketSignaling listener to handle incoming offer messages from both direct media servers (without id routing) and relayed signaling servers.
   - Configured answer generation with video receiving constraints (OfferToReceiveVideo: true, OfferToReceiveAudio: true).
   - Automatically returns generated SDP Answer back over WebSocket.

3. **Inbound Standalone Track Handling**:
   - Updated _peerConnection.onTrack to support both stream-bundled tracks and standalone unified-plan tracks using createLocalMediaStream('remote_stream') and ddTrack(event.track).

4. **ICE Candidate Forwarding**:
   - Enhanced candidate dispatching to work reliably even when Room ID is empty.
