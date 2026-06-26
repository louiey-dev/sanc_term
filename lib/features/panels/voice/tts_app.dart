import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

final TextEditingController tts1Controller = TextEditingController(
  text: '헬로매직? 정수 100미리 출수해줘',
);

final TextEditingController tts2Controller = TextEditingController(
  text: '헬로매직? 온수 200미리 출수해줘',
);

final TextEditingController tts3Controller = TextEditingController(
  text: '헬로매직? 냉수 200미리 출수해줘',
);

final TextEditingController tts4Controller = TextEditingController(
  text: '매직 정지',
);

final TextEditingController tts5Controller = TextEditingController(
  text: '헬로매직?온수?200미리?출수해줘',
);

class TtsPanel extends ConsumerStatefulWidget {
  const TtsPanel({super.key});

  @override
  ConsumerState<TtsPanel> createState() => _TtsPanelState();
}

class _TtsPanelState extends ConsumerState<TtsPanel> {
  final FlutterTts flutterTts = FlutterTts();

  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  double pauseMs = 1000; // Default pause between parts

  Completer<void>?
  _currentSpeechCompleter; // Added for managing segment completion
  bool isSpeaking = false;

  /// False when the flutter_tts plugin failed to initialize (e.g. the running
  /// binary predates the plugin and a full restart is needed). Keeps the panel
  /// usable instead of crashing.
  bool _ttsAvailable = true;

  /// The error captured during init, shown in the panel for diagnosis.
  String? _ttsError;

  List<dynamic> languages = ["ko-KR"];
  List<dynamic> voices = [];
  String? selectedLanguage;

  // List<dynamic> _allVoices = [];
  // List<dynamic> _filteredVoices = [];
  // Map<String, String>? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    // Set handlers
    flutterTts.setStartHandler(() {
      setState(() => isSpeaking = true);
      // If a completer exists, it means _speakWithPauses is active.
      // No need to complete it here, as start handler is just for state.
    });

    flutterTts.setCompletionHandler(() {
      if (_currentSpeechCompleter != null &&
          !_currentSpeechCompleter!.isCompleted) {
        _currentSpeechCompleter!.complete();
      } else {
        setState(
          () => isSpeaking = false,
        ); // For _speak calls or if no completer is active
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (_currentSpeechCompleter != null &&
          !_currentSpeechCompleter!.isCompleted) {
        _currentSpeechCompleter!.completeError(msg);
      }
      setState(() => isSpeaking = false); // Always set to false on error
    });

    try {
      // Get available languages
      List<dynamic> fetchedLanguages = await flutterTts.getLanguages ?? [];
      // Ensure unique languages and convert to List<String>
      languages = fetchedLanguages.map((e) => e.toString()).toSet().toList();

      voices = await flutterTts.getVoices ?? [];

      // Ensure selectedLanguage is valid. If "en-US" is not available,
      // default to the first available language, or null if none are found.
      if (!languages.contains(selectedLanguage) && languages.isNotEmpty) {
        selectedLanguage = languages.first;
      } else if (languages.isEmpty) {
        selectedLanguage = null; // No languages available
      }

      // Default settings
      if (selectedLanguage != null) {
        await flutterTts.setLanguage(selectedLanguage!);
      }
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      _ttsAvailable = true;
    } catch (e, st) {
      // flutter_tts failed to initialize — capture the real error so we can
      // tell a MissingPluginException (needs full rebuild) from a runtime/
      // engine failure. Keep the UI alive and disable playback.
      _ttsAvailable = false;
      _ttsError = '$e';
      debugPrint('flutter_tts init failed: $e\n$st');
    }

    // Update the UI after initialization
    if (mounted) setState(() {});
  }

  Future<void> _speak(String ttsString) async {
    if (ttsString.isEmpty) return;

    // If _speakWithPauses was running, complete its completer with an error to stop it.
    if (_currentSpeechCompleter != null &&
        !_currentSpeechCompleter!.isCompleted) {
      _currentSpeechCompleter!.completeError(
        "New speech initiated, previous interrupted.",
      );
    }
    _currentSpeechCompleter =
        null; // Clear it as this is a single speak operation

    sendBoardCommand(ref, context, 'Speaking: $ttsString');

    setState(() => isSpeaking = true); // Set true immediately
    try {
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      await flutterTts.speak(ttsString);
      // setCompletionHandler will set isSpeaking = false when speech finishes.
    } catch (_) {
      if (mounted) setState(() => isSpeaking = false);
    }
  }

  Future<void> _stop() async {
    try {
      await flutterTts.stop();
    } catch (_) {
      // Plugin unavailable — nothing to stop.
    }
    if (_currentSpeechCompleter != null &&
        !_currentSpeechCompleter!.isCompleted) {
      _currentSpeechCompleter!.completeError(
        "Stopped by user",
      ); // Complete with error if stopped
    }
    setState(() => isSpeaking = false);
  }

  Future<void> _speakWithPauses(String ttsString) async {
    if (ttsString.trim().isEmpty) return;

    sendBoardCommand(ref, context, 'Speaking: $ttsString');

    setState(() {
      isSpeaking = true;
    });

    // Split text by "." or "!" or "?" or manually by comma
    List<String> parts = ttsString
        .split(
          RegExp(r'[.?!,]\s*'),
        ) // Split by '.', '!', '?', or ',' followed by optional whitespace
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) => part.trim(),
        ) // Trim each part to remove leading/trailing whitespace
        .toList();

    for (int i = 0; i < parts.length; i++) {
      if (!isSpeaking) {
        // Check if speaking was stopped externally (e.g., by _stop() or another _speak() call)
        break;
      }

      _currentSpeechCompleter =
          Completer<void>(); // Create a new completer for this segment
      try {
        await flutterTts.speak(parts[i].trim());
        await _currentSpeechCompleter!
            .future; // Wait for this segment to complete
      } catch (e) {
        break; // Stop if there was an error, it was stopped, or plugin missing
      }

      // Add pause between parts (except after last part)
      if (i < parts.length - 1) {
        await Future.delayed(Duration(milliseconds: pauseMs.toInt()));
      }
    }

    _currentSpeechCompleter =
        null; // Reset completer after all parts are done or stopped
    setState(() {
      isSpeaking = false;
    });
  }

  _ttsMenu() {
    return Column(
      spacing: 8,
      children: [
        TtsPlay(
          ttsController: tts1Controller,
          onPlay: () => _speak(tts1Controller.text),
          onStop: _stop,
        ),
        TtsPlay(
          ttsController: tts2Controller,
          onPlay: () => _speak(tts2Controller.text),
          onStop: _stop,
        ),
        TtsPlay(
          ttsController: tts3Controller,
          onPlay: () => _speak(tts3Controller.text),
          onStop: _stop,
        ),
        TtsPlay(
          ttsController: tts4Controller,
          onPlay: () => _speak(tts4Controller.text),
          onStop: _stop,
        ),
        TtsPlay(
          ttsController: tts5Controller,
          hintText:
              'Speak with pauses. Use "." or "!" or "?" to split sentences.',
          onPlay: () => _speakWithPauses(tts5Controller.text),
          onStop: _stop,
        ),
        Row(
          children: [
            _ttsSlider(
              volume,
              0.0,
              1.0,
              10,
              "volume",
              (value) => setState(() => volume = value),
            ),
            _ttsSlider(
              rate,
              0.1,
              1.0,
              9,
              "Speech Rate",
              (value) => setState(() => rate = value),
            ),
          ],
        ),
        Row(
          children: [
            _ttsSlider(
              pitch,
              0.5,
              2.0,
              15,
              "Pitch",
              (value) => setState(() => pitch = value),
            ),
            _ttsSlider(
              pauseMs,
              0.0,
              2000,
              20,
              "Pause (ms)",
              (value) => setState(() => pauseMs = value),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyPanelBody(
      title: 'TTS OnVoice',
      subtitle: 'Play Text to speech on device',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_ttsAvailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'TTS engine not initialized.'
                      '${_ttsError != null ? '\n$_ttsError' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _ttsMenu(),
        ],
      ),
    );
  }

  Widget _ttsSlider(
    double value,
    double min,
    double max,
    int division,
    String label,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.normal)),

        Slider(
          value: value,
          min: min,
          max: max,
          divisions: division,
          label: value.toStringAsFixed(1),
          onChanged: (value) {
            onChanged(value);
          },
        ),
      ],
    );
  }
}

class TtsPlay extends StatelessWidget {
  final String ttsCommand;
  final TextEditingController ttsController;
  final IconData playIcon;
  final IconData stopIcon;
  final double width;
  final String hintText;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  const TtsPlay({
    super.key,
    this.ttsCommand = '',
    this.playIcon = Icons.play_arrow,
    this.stopIcon = Icons.stop,
    this.width = 400,
    this.hintText = '',
    required this.ttsController,
    required this.onPlay,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 34,
          width: width,
          child: TextField(
            controller: ttsController,
            decoration: InputDecoration(
              labelText: ttsCommand,
              border: const OutlineInputBorder(),
              hint: Text(hintText),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: onPlay, icon: Icon(playIcon)),
        IconButton(onPressed: onStop, icon: Icon(stopIcon)),
      ],
    );
  }
}
