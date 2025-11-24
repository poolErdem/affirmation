import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  double volume = 1.0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sound",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // SOUND SWITCH
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.teal.shade600, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Enable Sound",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                ),
                Switch(
                  value: appState.isSoundEnabled,
                  activeThumbColor: Colors.teal,
                  onChanged: (_) {
                    appState.toggleSound();
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // VOLUME SLIDER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Volume",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: volume,
                    min: 0,
                    max: 1,
                    activeColor: Colors.teal,
                    onChanged: (v) {
                      setState(() => volume = v);
                      appState.setVolume(v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // TEST SOUND
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play Test Sound"),
              onPressed: () {
                appState.playThemeSound();
              },
            ),
          ],
        ),
      ),
    );
  }
}
