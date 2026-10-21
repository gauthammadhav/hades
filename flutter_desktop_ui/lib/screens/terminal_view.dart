import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class TerminalView extends StatefulWidget {
  const TerminalView({super.key});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _lines = [
    '[SYSTEM] HADES Broker connected to /dev/ttyACM0',
    '[SYSTEM] Baud: 115200, Parity: None, Data: 8, Stop: 1',
    '[UART] ESP-ROM:esp32s3-20210327',
    '[UART] rst:0x1 (POWERON),boot:0x8 (SPI_FAST_FLASH_BOOT)',
    '[UART] SPIWP:0xee',
    '[UART] mode:DIO, clock div:1',
    '[UART] load:0x3fce3808,len:0x16b0',
    '[UART] load:0x403c9700,len:0x4',
    '[UART] [HADES-APP] Initializing CAN bus driver... [OK]',
    '[UART] [HADES-APP] Microcontroller firmware v1.4.2 started.',
    '[UART] [HADES-APP] Listening for commands on /dev/ttyACM0...',
  ];

  void _sendCommand() {
    final text = _commandController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _lines.add('> $text');
      if (text.toLowerCase() == 'help') {
        _lines.add(
          '[UART] Available commands: status, ping, reboot, idf-version, dump, hades',
        );
      } else if (text.toLowerCase() == 'hades' ||
          text.toLowerCase() == 'shell') {
        _lines.add(
          '[SECURITY] HADES Core intentionally exposes no remote shell over HTTP/WS.',
        );
        _lines.add(
          '[SECURITY] To attach directly on the host runtime: hades shell <session-id>',
        );
      } else if (text.toLowerCase() == 'ping') {
        _lines.add('[UART] PONG (latency: 1.2ms)');
      } else if (text.toLowerCase() == 'status') {
        _lines.add(
          '[UART] ESP32-S3: Core 0 [OK], Core 1 [OK], Free Heap: 284 KB, Flash: 8MB',
        );
      } else {
        _lines.add('[UART] Command "$text" acknowledged by firmware.');
      }
    });

    _commandController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Sandbox Shell & Serial',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Interactive container terminal and microcontroller UART serial stream',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chipMintBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.radio_button_checked_rounded,
                        size: 10,
                        color: AppColors.ok,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '115200 8-N-1',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lines.clear();
                      _lines.add('[SYSTEM] Terminal cleared.');
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Terminal Console Box
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.softShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    Color lineColor = AppColors.logNormal;

                    if (line.startsWith('>')) {
                      lineColor = AppColors.logAudit;
                    } else if (line.contains('[SYSTEM]')) {
                      lineColor = AppColors.info;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          height: 1.4,
                          color: lineColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Command Input Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '>',
                            style: TextStyle(
                              color: AppColors.logAudit,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _commandController,
                              onSubmitted: (_) => _sendCommand(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Type command (e.g. status, ping, help)...',
                                hintStyle: TextStyle(
                                  color: AppColors.heroSubtext,
                                  fontSize: 11,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _sendCommand,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ok,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
