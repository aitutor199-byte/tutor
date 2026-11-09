import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String nameEn;
  final String nameUr;
  final String namePs;
  final IconData icon;
  final Color color;
  final String descriptionEn;
  final String descriptionUr;
  final String descriptionPs;

  const Subject({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.namePs,
    required this.icon,
    required this.color,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.descriptionPs,
  });

  String getName(String languageCode) {
    switch (languageCode) {
      case 'ur':
        return nameUr;
      case 'ps':
        return namePs;
      default:
        return nameEn;
    }
  }

  String getDescription(String languageCode) {
    switch (languageCode) {
      case 'ur':
        return descriptionUr;
      case 'ps':
        return descriptionPs;
      default:
        return descriptionEn;
    }
  }
}

class SubjectData {
  static const List<Subject> subjects = [
    Subject(
      id: 'mathematics',
      nameEn: 'Mathematics',
      nameUr: 'ریاضی',
      namePs: 'ریاضی',
      icon: Icons.calculate_rounded,
      color: Color(0xFF4285F4),
      descriptionEn: 'Algebra, Geometry, Calculus & more',
      descriptionUr: 'الجبرا، جیومیٹری، کیلکولس اور مزید',
      descriptionPs: 'الجبرا، جیومیټري، کلکولس او نور',
    ),
    Subject(
      id: 'science',
      nameEn: 'Science',
      nameUr: 'سائنس',
      namePs: 'ساینس',
      icon: Icons.science_rounded,
      color: Color(0xFF34A853),
      descriptionEn: 'Physics, Chemistry, Biology & more',
      descriptionUr: 'فزکس، کیمسٹری، بایولوجی اور مزید',
      descriptionPs: 'فزیکس، کیمیا، بیولوژي او نور',
    ),
    Subject(
      id: 'english',
      nameEn: 'English',
      nameUr: 'انگریزی',
      namePs: 'انګلیسي',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFFBBC04),
      descriptionEn: 'Grammar, Writing, Literature & more',
      descriptionUr: 'گرامر، تحریر، ادب اور مزید',
      descriptionPs: 'ګرامر، لیکنه، ادبیات او نور',
    ),
    Subject(
      id: 'computer_science',
      nameEn: 'Computer Science',
      nameUr: 'کمپیوٹر سائنس',
      namePs: 'کمپیوټر ساینس',
      icon: Icons.computer_rounded,
      color: Color(0xFF9C27B0),
      descriptionEn: 'Programming, Algorithms & more',
      descriptionUr: 'پروگرامنگ، الگورتھم اور مزید',
      descriptionPs: 'پروګرامینګ، الګوریتم او نور',
    ),
    Subject(
      id: 'university',
      nameEn: 'University',
      nameUr: 'یونیورسٹی',
      namePs: 'پوهنتون',
      icon: Icons.school_rounded,
      color: Color(0xFFE91E63),
      descriptionEn: 'Advanced academic subjects',
      descriptionUr: 'اعلیٰ تعلیمی مضامین',
      descriptionPs: 'لوړې زده کړې مضامین',
    ),
    Subject(
      id: 'ask_anything',
      nameEn: 'Ask Anything',
      nameUr: 'کچھ بھی پوچھیں',
      namePs: 'هر څه وپوښتئ',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFFFF9800),
      descriptionEn: 'Any question, any topic',
      descriptionUr: 'کوئی بھی سوال، کوئی بھی موضوع',
      descriptionPs: 'هر پوښتنه، هر موضوع',
    ),
  ];
}
