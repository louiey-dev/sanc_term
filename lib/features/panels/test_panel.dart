import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class TestPanel extends StatefulWidget {
  const TestPanel({super.key});

  @override
  State<TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<TestPanel> {
  @override
  Widget build(BuildContext context) {
    return MyPanel(
      panelTitle: 'Test Panel',
      panelSubtitle: 'Test panel subtitle',
      icon: Icons.settings,
      panelActions: [
        PanelActionButton(
          icon: Icons.info_outline,
          label: 'Test Action',
          onPressed: () {
            if (kDebugMode) {
              print("Test action executed");
            }
          },
        ),
      ],
      spacing: 8,
      children: [
        PanelBody(children: [_menu1()]),
        PanelBody(children: [_menu2()]),
      ],
    );
  }

  _menu1() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Modal Bottom Sheet'),
                ElevatedButton(
                  child: const Text('Close Bottom Sheet'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _menu2() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Modal Bottom Sheet'),
                ElevatedButton(
                  child: const Text('Close Bottom Sheet'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
