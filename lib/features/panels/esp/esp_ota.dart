import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// ESP OTA firmware upload. Picks a .bin and POSTs it (raw body) to the OTA
/// server. Uses dart:io HttpClient (no extra packages).
class EspOtaPanel extends ConsumerStatefulWidget {
  const EspOtaPanel({super.key});

  @override
  ConsumerState<EspOtaPanel> createState() => _EspOtaPanelState();
}

class _EspOtaPanelState extends ConsumerState<EspOtaPanel> {
  final _url = TextEditingController(text: 'http://10.10.0.1/update');
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );
    if (picked == null || picked.files.single.path == null) return;

    setState(() {
      _busy = true;
      _status = 'Uploading ${picked.files.single.name}…';
    });
    try {
      final bytes = await File(picked.files.single.path!).readAsBytes();
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse(_url.text));
      req.headers.contentType = ContentType('text', 'plain');
      req.headers.set('update-model', 'esp-at-ota');
      req.headers.set(HttpHeaders.contentLengthHeader, bytes.length);
      req.add(bytes);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      if (!mounted) return;
      setState(() => _status = 'HTTP ${resp.statusCode}: $body');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.cloud_upload,
      panelTitle: 'ESP OTA Update',
      panelSubtitle: 'Over-the-air firmware updates for ESP devices',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.cloud_upload,
          title: 'OTA Firmware Upload',
          subtitle: 'POST a .bin to the OTA server (e.g. ESP-AT-OTA)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: TextField(
                      controller: _url,
                      decoration: const InputDecoration(
                        labelText: 'Target URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.file_upload,
                    label: _busy ? 'Uploading…' : 'Pick & Upload .bin',
                    tooltipStr: 'Select firmware and upload',
                    onPressed: _busy ? null : _upload,
                  ),
                ],
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  _status!,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Consolas',
                    color: c.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
