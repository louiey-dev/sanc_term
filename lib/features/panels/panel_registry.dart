import 'package:flutter/material.dart';
import 'package:sanc_term/features/panels/bluetooth/bluetooth_le.dart';
import 'package:sanc_term/features/panels/common/cm_cmd_history.dart';
import 'package:sanc_term/features/panels/common/cm_general_settings.dart';
import 'package:sanc_term/features/panels/common/cm_time_setting.dart';
import 'package:sanc_term/features/panels/common/cm_udp.dart';
import 'package:sanc_term/features/panels/common/stub_panel.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_cpu.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_display.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_gpio.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_memory.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_peripheral.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_power.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_rtc_sensor.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_storage.dart';
import 'package:sanc_term/features/panels/diagnostics/dn_wifi_ble.dart';
import 'package:sanc_term/features/panels/esp/esp_at.dart';
import 'package:sanc_term/features/panels/esp/esp_ota.dart';
import 'package:sanc_term/features/panels/models/panel_entry.dart';
import 'package:sanc_term/features/panels/nvidia/nv_audio.dart';
import 'package:sanc_term/features/panels/nvidia/nv_ethernet.dart';
import 'package:sanc_term/features/panels/nvidia/nv_gpio.dart';
import 'package:sanc_term/features/panels/nvidia/nv_hdmi.dart';
import 'package:sanc_term/features/panels/nvidia/nv_leds.dart';
import 'package:sanc_term/features/panels/nvidia/nv_nvme.dart';
import 'package:sanc_term/features/panels/nvidia/nv_settings.dart';
import 'package:sanc_term/features/panels/nvidia/nv_uart.dart';
import 'package:sanc_term/features/panels/nvidia/nv_usb.dart';
import 'package:sanc_term/features/panels/rockchip/rc_display.dart';
import 'package:sanc_term/features/panels/rockchip/rc_gpio.dart';
import 'package:sanc_term/features/panels/rockchip/rc_i2c.dart';
import 'package:sanc_term/features/panels/rockchip/rc_mpp.dart';
import 'package:sanc_term/features/panels/rockchip/rc_network.dart';
import 'package:sanc_term/features/panels/rockchip/rc_sensors.dart';
import 'package:sanc_term/features/panels/rockchip/rc_settings.dart';
import 'package:sanc_term/features/panels/rockchip/rc_storage.dart';
import 'package:sanc_term/features/panels/rockchip/rc_uart.dart';
import 'package:sanc_term/features/panels/rockchip/rc_usb.dart';
import 'package:sanc_term/features/panels/voice/odv_default.dart';

const panelGroups = [
  PanelGroup(
    title: 'COMMON',
    icon: Icons.widgets,
    items: [
      PanelEntry(
        id: 'cm_cmd_history',
        label: 'Cmd History',
        description: 'Recent & favorite commands',
        icon: Icons.history,
      ),
      PanelEntry(
        id: 'cm_general_settings',
        label: 'General Settings',
        description: 'Common configurations',
        icon: Icons.settings,
      ),
      PanelEntry(
        id: 'cm_time_setting',
        label: 'Time Setting',
        description: 'Time configurations',
        icon: Icons.timer,
      ),
      PanelEntry(
        id: 'cm_udp',
        label: 'UDP',
        description: 'Send/receive UDP datagrams',
        icon: Icons.wifi_tethering,
      ),
    ],
  ),
  PanelGroup(
    title: 'ROCKCHIP',
    icon: Icons.developer_board,
    items: [
      PanelEntry(
        id: 'rc_settings',
        label: 'Rockchip Settings',
        description: 'Rockchip board config',
        icon: Icons.settings_applications,
      ),
      PanelEntry(
        id: 'rc_gpio',
        label: 'GPIO',
        description: 'Configure and control GPIO pins',
        icon: Icons.developer_board,
      ),
      PanelEntry(
        id: 'rc_uart',
        label: 'UART',
        description: 'Configure UART and transfer data',
        icon: Icons.cable,
      ),
      PanelEntry(
        id: 'rc_i2c',
        label: 'I2C',
        description: 'Manage I2C devices (RTC, Touch)',
        icon: Icons.cable,
      ),
      PanelEntry(
        id: 'rc_sensors',
        label: 'Sensors',
        description: 'Manage light and backlight sensors',
        icon: Icons.sensors,
      ),
      PanelEntry(
        id: 'rc_display',
        label: 'Display',
        description: 'Display settings',
        icon: Icons.monitor,
      ),
      PanelEntry(
        id: 'rc_mpp',
        label: 'MPP',
        description: 'Media Processing',
        icon: Icons.video_settings,
      ),
      PanelEntry(
        id: 'rc_network',
        label: 'Network',
        description: 'Ethernet config',
        icon: Icons.lan,
      ),
      PanelEntry(
        id: 'rc_storage',
        label: 'Storage',
        description: 'eMMC / NVMe',
        icon: Icons.storage,
      ),
      PanelEntry(
        id: 'rc_usb',
        label: 'USB',
        description: 'USB ports',
        icon: Icons.usb,
      ),
    ],
  ),
  PanelGroup(
    title: 'NVIDIA',
    icon: Icons.memory,
    items: [
      PanelEntry(
        id: 'nv_settings',
        label: 'nVidia Settings',
        description: 'nVidia board config',
        icon: Icons.settings_applications,
      ),
      PanelEntry(
        id: 'nv_gpio',
        label: 'GPIO',
        description: 'nVidia GPIO controls',
        icon: Icons.developer_board,
      ),
      PanelEntry(
        id: 'nv_hdmi',
        label: 'HDMI',
        description: 'nVidia HDMI settings',
        icon: Icons.tv,
      ),
      PanelEntry(
        id: 'nv_ethernet',
        label: 'Ethernet',
        description: 'nVidia Ethernet settings',
        icon: Icons.lan,
      ),
      PanelEntry(
        id: 'nv_uart',
        label: 'UART',
        description: 'nVidia UART controls',
        icon: Icons.cable,
      ),
      PanelEntry(
        id: 'nv_leds',
        label: 'LEDs',
        description: 'nVidia LED controls',
        icon: Icons.light_mode,
      ),
      PanelEntry(
        id: 'nv_nvme',
        label: 'NVMe',
        description: 'nVidia NVMe settings',
        icon: Icons.storage,
      ),
      PanelEntry(
        id: 'nv_usb',
        label: 'USB',
        description: 'nVidia USB settings',
        icon: Icons.usb,
      ),
      PanelEntry(
        id: 'nv_audio',
        label: 'Audio',
        description: 'nVidia audio settings',
        icon: Icons.audiotrack,
      ),
    ],
  ),
  PanelGroup(
    title: 'DIAGNOSTICS',
    icon: Icons.show_chart,
    items: [
      PanelEntry(
        id: 'dn_power',
        label: 'Power Monitor',
        description: 'Voltage & current monitoring',
        icon: Icons.bolt,
      ),
      PanelEntry(
        id: 'dn_cpu',
        label: 'CPU Check',
        description: 'Processor diagnostics',
        icon: Icons.memory,
      ),
      PanelEntry(
        id: 'dn_memory',
        label: 'Memory Check',
        description: 'RAM & cache analysis',
        icon: Icons.sd_storage,
      ),
      PanelEntry(
        id: 'dn_storage',
        label: 'Storage Check',
        description: 'Flash & disk diagnostics',
        icon: Icons.storage,
      ),
      PanelEntry(
        id: 'dn_peripheral',
        label: 'Peripheral Check',
        description: 'UART, I2C, SPI, ETH, USB',
        icon: Icons.cable,
      ),
      PanelEntry(
        id: 'dn_display',
        label: 'Display Check',
        description: 'Screen & panel testing',
        icon: Icons.monitor,
      ),
      PanelEntry(
        id: 'dn_wifi_ble',
        label: 'WiFi / BLE',
        description: 'Wireless connectivity',
        icon: Icons.wifi,
      ),
      PanelEntry(
        id: 'dn_gpio',
        label: 'GPIO Control',
        description: 'Pin configuration & control',
        icon: Icons.developer_board,
      ),
      PanelEntry(
        id: 'dn_rtc_sensor',
        label: 'RTC / WDT / Sensor',
        description: 'Timers, watchdog & sensors',
        icon: Icons.schedule,
      ),
    ],
  ),
  PanelGroup(
    title: 'ESPRESSIF',
    icon: Icons.wifi,
    items: [
      PanelEntry(
        id: 'esp_at',
        label: 'ESP AT Commands',
        description: 'ESP AT command quick access panel',
        icon: Icons.list,
      ),
      PanelEntry(
        id: 'esp_ota',
        label: 'ESP OTA Update',
        description: 'Over-the-air firmware updates',
        icon: Icons.cloud_upload,
      ),
    ],
  ),
  PanelGroup(
    title: 'LTE MODULE',
    icon: Icons.lte_plus_mobiledata,
    items: [
      PanelEntry(
        id: 'lte_module',
        label: 'LTE Module',
        description: 'LTE Module settings and tools',
        icon: Icons.lte_plus_mobiledata,
      ),
    ],
  ),
  PanelGroup(
    title: 'ON-DEVICE VOICE',
    icon: Icons.record_voice_over,
    items: [
      PanelEntry(
        id: 'odv_default',
        label: 'On-Device Voice',
        description: 'Voice demo settings and controls',
        icon: Icons.mic,
      ),
    ],
  ),
  PanelGroup(
    title: 'Bluetooth LE',
    icon: Icons.bluetooth,
    items: [
      PanelEntry(
        id: 'ble_panel',
        label: 'Bluetooth LE',
        description: 'Bluetooth LE quick access panel',
        icon: Icons.bluetooth,
      ),
    ],
  ),
];

// Derived from panelGroups — every panel defaults to a StubPanel. Add a real
// builder to [_realPanels] below to override the stub for that id.
final Map<String, Widget Function()> panelRegistry = {
  for (final group in panelGroups)
    for (final entry in group.items) entry.id: () => StubPanel(entry: entry),
  ..._realPanels,
};

/// Ids that have a real implementation. These override the stub above.
final Map<String, Widget Function()> _realPanels = {
  // Common
  'cm_cmd_history': () => const CmCmdHistoryPanel(),
  'cm_general_settings': () => const CmGeneralSettingsPanel(),
  'cm_time_setting': () => const CmTimeSettingPanel(),
  'cm_udp': () => const CmUdpPanel(),
  // Diagnostics
  'dn_power': () => const DnPowerPanel(),
  'dn_cpu': () => const DnCpuPanel(),
  'dn_memory': () => const DnMemoryPanel(),
  'dn_storage': () => const DnStoragePanel(),
  'dn_peripheral': () => const DnPeripheralPanel(),
  'dn_display': () => const DnDisplayPanel(),
  'dn_wifi_ble': () => const DnWifiBlePanel(),
  'dn_gpio': () => const DnGpioPanel(),
  'dn_rtc_sensor': () => const DnRtcSensorPanel(),
  // NVIDIA
  'nv_settings': () => const NvSettingsPanel(),
  'nv_gpio': () => const NvGpioPanel(),
  'nv_hdmi': () => const NvHdmiPanel(),
  'nv_ethernet': () => const NvEthernetPanel(),
  'nv_uart': () => const NvUartPanel(),
  'nv_leds': () => const NvLedPanel(),
  'nv_nvme': () => const NvNvmePanel(),
  'nv_usb': () => const NvUsbPanel(),
  'nv_audio': () => const NvAudioPanel(),
  // Rockchip
  'rc_settings': () => const RcSettingsPanel(),
  'rc_gpio': () => const RcGpioPanel(),
  'rc_uart': () => const RcUartPanel(),
  'rc_i2c': () => const RcI2cPanel(),
  'rc_sensors': () => const RcSensorsPanel(),
  'rc_display': () => const RcDisplayPanel(),
  'rc_mpp': () => const RcMppPanel(),
  'rc_network': () => const RcNetworkPanel(),
  'rc_storage': () => const RcStoragePanel(),
  'rc_usb': () => const RcUsbPanel(),
  // Espressif
  'esp_at': () => const EspAtPanel(),
  'esp_ota': () => const EspOtaPanel(),
  // On-device voice
  'odv_default': () => const OnDeviceVoicePanel(),
  // Bluetooth LE
  'ble_panel': () => const BlePanel(),
};
