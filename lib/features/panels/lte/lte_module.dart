import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class LteModulePanel extends ConsumerStatefulWidget {
  const LteModulePanel({super.key});

  @override
  ConsumerState<LteModulePanel> createState() => _LteModulePanelState();
}

class _LteModulePanelState extends ConsumerState<LteModulePanel> {
  final _urlController = TextEditingController(
    text: "https://ingest-api-hbnqycioma-du.a.run.app/upload",
  );
  final _postMessageController = TextEditingController(
    text: "Hello there!",
  );

  @override
  void dispose() {
    _urlController.dispose();
    _postMessageController.dispose();
    super.dispose();
  }

  void _send(String cmd) {
    sendBoardCommand(ref, context, 'lte at $cmd OK 1000', terminator: '\n');
  }

  PanelActionButton _btn(String label, String cmd, String tip) =>
      PanelActionButton(
        icon: Icons.bolt,
        label: label,
        tooltipStr: tip,
        onPressed: () => _send(cmd),
      );

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.lte_plus_mobiledata,
      panelTitle: 'Quectel EC800G-CN LTE Module',
      panelSubtitle: 'LTE Module settings and tools',
      panelActions: [
        PanelActionButton(
          icon: Icons.info_outline,
          label: 'Info',
          tooltipStr: 'ATI',
          onPressed: () => _send('ATI'),
        ),
        PanelActionButton(
          icon: Icons.info_outline,
          label: 'FW Ver',
          tooltipStr: 'AT+CGMR',
          onPressed: () => _send('AT+CGMR'),
        ),
      ],
      children: [
        MyPanelBody(
          icon: Icons.bug_report_outlined,
          title: 'Test Mode (OCR)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn('AT+QHTTPCFG=', 'AT+QHTTPCFG="contextid",1', 'Configure Parameters for HTTP(S) Server'),
                  _btn('AT+QIACT?', 'AT+QIACT?', 'Check if PDP context is activated (internet is ready)'),
                  _btn('AT+QICSGP=', 'AT+QICSGP=1,1,"lte.ktfwing.com","","",1', 'PDP context configuration KT APN'),
                  _btn('AT+QHTTPCFG=reqheader', 'AT+QHTTPCFG="reqheader/add","Content-Type","image/jpeg"', 'Explicitly configure content type for images'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
                      decoration: const InputDecoration(
                        labelText: 'HTTP URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.link,
                    label: 'Set URL',
                    tooltipStr: 'AT+QHTTPURL=<len>,80',
                    onPressed: () {
                      final len = _urlController.text.length;
                      _send('AT+QHTTPURL=$len,80');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!context.mounted) return;
                        sendBoardCommand(ref, context, _urlController.text, terminator: '\n');
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _postMessageController,
                      style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
                      decoration: const InputDecoration(
                        labelText: 'POST Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'HTTP POST',
                    tooltipStr: 'AT+QHTTPPOST=<len>,60,60',
                    onPressed: () {
                      final len = _postMessageController.text.length;
                      _send('AT+QHTTPPOST=$len,60,60');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!context.mounted) return;
                        sendBoardCommand(ref, context, _postMessageController.text, terminator: '\n');
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.bolt,
          title: 'AT Commands General',
          subtitle: 'Common AT commands for diagnostics',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT&V', 'AT&V', 'Display current configuration settings'),
              _btn('AT+CSQ', 'AT+CSQ', 'Display signal quality'),
              _btn('AT+CGATT?', 'AT+CGATT?', 'Check network attachment status'),
              _btn('AT+CREG?', 'AT+CREG?', 'Check network registration status'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.sim_card,
          title: 'USIM / Card',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT+CPIN?', 'AT+CPIN?', 'Check SIM card status'),
              _btn('AT+CLCK="SC",2', 'AT+CLCK="SC",2', 'Check SIM card lock status'),
              _btn('AT+QCCID', 'AT+QCCID', 'Get SIM ICCID'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.settings_input_antenna,
          title: 'Network Service',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT+CEREG?', 'AT+CEREG?', 'Check LTE network registration status'),
              _btn('AT+CGREG?', 'AT+CGREG?', 'Check packet-switched (data) registration'),
              _btn('AT+QCSQ', 'AT+QCSQ', 'LTE-specific signal info'),
              _btn('AT+QNWINFO', 'AT+QNWINFO', 'LTE Extended signal info'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.phone,
          title: 'Call & Phonebook & SMS',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT+CLCC', 'AT+CLCC', 'Check current call status'),
              _btn('AT+CPBR=1,100', 'AT+CPBR=1,100', 'List phonebook entries 1..100'),
              _btn('AT+CMGS', 'AT+CMGS="1234567890"', 'Send test SMS'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.http,
          title: 'HTTP Service',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn('AT+QIACT=1', 'AT+QIACT=1', 'Activate PDP context'),
                  _btn('AT+HTTPINIT', 'AT+HTTPINIT', 'Initialize HTTP service'),
                  _btn('AT+HTTPPARA', 'AT+HTTPPARA="CID",1', 'Set HTTP parameters (CID=1)'),
                  _btn('AT+QHTTPPOST=?', 'AT+QHTTPPOST=?', 'Check QHTTPPOST support'),
                  _btn('AT+QHTTPCFG?', 'AT+QHTTPCFG?', 'Query HTTP configuration'),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.audiotrack,
          title: 'Audio Control',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT+CHFA?', 'AT+CHFA?', 'Query current audio profile'),
              _btn('Handset', 'AT+CHFA=0', 'Set audio profile to handset'),
              _btn('Loudspeaker', 'AT+CHFA=1', 'Set audio profile to loudspeaker'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.hardware,
          title: 'Hardware Control',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('AT+CGSN', 'AT+CGSN', 'Check hardware status / IMEI'),
              _btn('Reset', 'AT+CFUN=1,1', 'Reset the module'),
            ],
          ),
        ),
      ],
    );
  }
}
