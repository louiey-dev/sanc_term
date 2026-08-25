# WebRTC Video & Audio Track Toggle / Mute Fix

## Overview

Fixed the **Video Track: ON/OFF** and **Audio Track: ON/OFF** buttons in [lib/features/panels/common/cm_webrtc.dart](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart) to actively mute/unmute and disable/enable media tracks in real time and during SDP negotiation.

## Root Cause

1. Previously, clicking the FilterChip only mutated the Riverpod state variable without updating the underlying MediaStreamTrack.enabled state on the active _remoteRenderer.srcObject or transceivers.
2. The SDP answer creation hardcoded OfferToReceiveVideo: true and OfferToReceiveAudio: true, ignoring the user's toggle setting.
3. The viewport always attempted to render _remoteRenderer even if enableVideo was alse.

## Changes

1. **Live Track Control (_toggleVideoTrack / _toggleAudioTrack)**:
   - Updates 	rack.enabled across all active video and audio tracks in _remoteRenderer.srcObject.
   - Iterates through _peerConnection.getTransceivers() to update receiver track state.
2. **SDP Constraints in Negotiation**:
   - createAnswer now dynamically reflects params.enableVideo and params.enableAudio.
3. **UI Feedback**:
   - When **Video Track: OFF** is selected, the viewport displays a dedicated Video Track OFF (Muted) state and halts rendering.
