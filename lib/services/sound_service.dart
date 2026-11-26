import 'package:flutter/services.dart';

class SoundService {
  bool soundEnabled;
  bool vibrationEnabled;

  SoundService({this.soundEnabled = true, this.vibrationEnabled = true});

  void playCard() {
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
    if (vibrationEnabled) HapticFeedback.lightImpact();
  }

  void playSpecialCard() {
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
    if (vibrationEnabled) HapticFeedback.mediumImpact();
  }

  void playDraw() {
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
    if (vibrationEnabled) HapticFeedback.selectionClick();
  }

  void playUno() {
    if (soundEnabled) SystemSound.play(SystemSoundType.alert);
    if (vibrationEnabled) HapticFeedback.heavyImpact();
  }

  void playPenalty() {
    if (soundEnabled) SystemSound.play(SystemSoundType.alert);
    if (vibrationEnabled) HapticFeedback.vibrate();
  }

  void playWin() {
    if (soundEnabled) SystemSound.play(SystemSoundType.alert);
    if (vibrationEnabled) HapticFeedback.heavyImpact();
  }
}
