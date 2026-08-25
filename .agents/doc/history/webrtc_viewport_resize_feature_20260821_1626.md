# WebRTC Live Video Viewport Resizing Feature

## Overview

Added interactive resizing controls and fullscreen viewing capabilities to the **Live Camera / Video Viewport** in [lib/features/panels/common/cm_webrtc.dart](file:///D:/GIT/GitHub/sanc_term/lib/features/panels/common/cm_webrtc.dart).

## Key Capabilities Added

1. **Draggable Bottom Handle**:
   - A drag bar at the bottom of the video container with esizeUpDown cursor.
   - Smooth continuous height adjustment from 180px up to 960px.
   - Double-clicking the bar toggles between 360px and 560px.

2. **Preset Height Quick Buttons**:
   - 240p, 360p, 480p, and 720p buttons in the card header.

3. **Fullscreen Dialog**:
   - Fullscreen button (Icons.fullscreen) in the header that opens a pop-out modal video view with aspect containment and escape-key close support.

4. **Hive Persistence**:
   - Viewport height is automatically saved to Hive (webrtc_viewport_height) across app sessions and panel navigation.
