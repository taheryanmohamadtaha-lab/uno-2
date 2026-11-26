import 'package:flutter/material.dart';

class GameCharacter {
  final String id;
  final String nameFa;
  final String nameEn;
  final String emoji;
  final Color primaryColor;
  final String styleFa;
  final String styleEn;
  final String winQuoteFa;
  final String loseQuoteFa;
  final String specialQuoteFa;
  final int unlockCost;

  const GameCharacter({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.emoji,
    required this.primaryColor,
    required this.styleFa,
    required this.styleEn,
    required this.winQuoteFa,
    required this.loseQuoteFa,
    required this.specialQuoteFa,
    this.unlockCost = 0,
  });

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String style(String lang) => lang == 'fa' ? styleFa : styleEn;
}

const List<GameCharacter> kGameCharacters = [
  GameCharacter(
    id: 'aria',
    nameFa: 'آریا',
    nameEn: 'Aria',
    emoji: '🦊',
    primaryColor: Color(0xFFF97316),
    styleFa: 'سریع و جسور',
    styleEn: 'Fast & Bold',
    winQuoteFa: 'سرعت عمل همیشه برنده است!',
    loseQuoteFa: 'دفعه بعد جبران می‌کنم!',
    specialQuoteFa: 'این کارت رو داشته باش!',
    unlockCost: 0,
  ),
  GameCharacter(
    id: 'parisa',
    nameFa: 'پریسا',
    nameEn: 'Parisa',
    emoji: '🦋',
    primaryColor: Color(0xFFEC4899),
    styleFa: 'حسابگر و آرام',
    styleEn: 'Calm Strategist',
    winQuoteFa: 'همه چیز طبق نقشه پیش رفت.',
    loseQuoteFa: 'بازی خوبی بود، تبریک!',
    specialQuoteFa: 'رنگ بازی عوض شد!',
    unlockCost: 0,
  ),
  GameCharacter(
    id: 'kian',
    nameFa: 'کیان',
    nameEn: 'Kian',
    emoji: '🦁',
    primaryColor: Color(0xFFEAB308),
    styleFa: 'تهاجمی و پرریسک',
    styleEn: 'Aggressive Tactician',
    winQuoteFa: 'سلطان میز بازی برگشت!',
    loseQuoteFa: 'شانس یارم نبود!',
    specialQuoteFa: 'وقت +4 رسیده!',
    unlockCost: 0,
  ),
  GameCharacter(
    id: 'niki',
    nameFa: 'نیکی',
    nameEn: 'Niki',
    emoji: '🐼',
    primaryColor: Color(0xFF10B981),
    styleFa: 'دفاعی و صبور',
    styleEn: 'Patient Defender',
    winQuoteFa: 'صبر و حوصله نتیجه داد.',
    loseQuoteFa: 'ای وای، نزدیک بود!',
    specialQuoteFa: 'ببخشید، نوبتت پرید!',
    unlockCost: 0,
  ),
  GameCharacter(
    id: 'sepehr',
    nameFa: 'سپهر',
    nameEn: 'Sepehr',
    emoji: '🦅',
    primaryColor: Color(0xFF3B82F6),
    styleFa: 'تیزبین و دقیق',
    styleEn: 'Sharp Observer',
    winQuoteFa: 'حرکتت رو از قبل پیش‌بینی کردم!',
    loseQuoteFa: 'عجب دست غیرمنتظره‌ای!',
    specialQuoteFa: 'جهت بازی برعکس شد!',
    unlockCost: 150,
  ),
  GameCharacter(
    id: 'tara',
    nameFa: 'تارا',
    nameEn: 'Tara',
    emoji: '🐱',
    primaryColor: Color(0xFF8B5CF6),
    styleFa: 'غیرقابل پیش‌بینی',
    styleEn: 'Wildcard Trickster',
    winQuoteFa: 'غافلگیر شدی، نه؟',
    loseQuoteFa: 'این بار تو بردی!',
    specialQuoteFa: 'یه سورپرایز کوچیک!',
    unlockCost: 200,
  ),
  GameCharacter(
    id: 'behzad',
    nameFa: 'بهزاد',
    nameEn: 'Behzad',
    emoji: '🐻',
    primaryColor: Color(0xFFEF4444),
    styleFa: 'محکم و مقاوم',
    styleEn: 'Steady Powerhouse',
    winQuoteFa: 'قدرت واقعی یعنی این!',
    loseQuoteFa: 'دستت درد نکنه، عالی بود.',
    specialQuoteFa: 'دوتا کارت بردار!',
    unlockCost: 250,
  ),
  GameCharacter(
    id: 'luna',
    nameFa: 'لونا',
    nameEn: 'Luna',
    emoji: '🦉',
    primaryColor: Color(0xFF06B6D4),
    styleFa: 'نابغه شب',
    styleEn: 'Night Genius',
    winQuoteFa: 'منطق همیشه پیروز است.',
    loseQuoteFa: 'باید بیشتر دقت می‌کردم.',
    specialQuoteFa: 'UNO! مراقب باش!',
    unlockCost: 300,
  ),
];

GameCharacter characterById(String id) =>
    kGameCharacters.firstWhere((c) => c.id == id, orElse: () => kGameCharacters.first);
