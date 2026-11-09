class EducationLevel {
  final String id;
  final String nameEn;
  final String nameUr;
  final String namePs;
  final String systemPromptHint;

  const EducationLevel({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.namePs,
    required this.systemPromptHint,
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
}

class EducationLevelData {
  static const List<EducationLevel> levels = [
    EducationLevel(
      id: 'primary',
      nameEn: 'Primary School (Class 1-5)',
      nameUr: 'پرائمری اسکول (جماعت 1-5)',
      namePs: 'ابتدايي ښوونځی (ټولګی 1-5)',
      systemPromptHint: 'The student is in primary school (ages 5-10). Use very simple language, short sentences, and lots of examples. Avoid complex terminology. Make learning fun and engaging.',
    ),
    EducationLevel(
      id: 'middle',
      nameEn: 'Middle School (Class 6-8)',
      nameUr: 'مڈل اسکول (جماعت 6-8)',
      namePs: 'منځنی ښوونځی (ټولګی 6-8)',
      systemPromptHint: 'The student is in middle school (ages 11-13). Use clear language with some technical terms. Provide step-by-step explanations. Encourage critical thinking.',
    ),
    EducationLevel(
      id: 'high',
      nameEn: 'High School (Class 9-12)',
      nameUr: 'ہائی اسکول (جماعت 9-12)',
      namePs: 'عالي ښوونځی (ټولګی 9-12)',
      systemPromptHint: 'The student is in high school (ages 14-18). Use appropriate academic language. Provide detailed explanations with proper terminology. Include formulas and proofs where relevant.',
    ),
    EducationLevel(
      id: 'college',
      nameEn: 'College (Intermediate)',
      nameUr: 'کالج (انٹرمیڈیٹ)',
      namePs: 'کالج (انټرمیډیټ)',
      systemPromptHint: 'The student is in college/intermediate level. Use academic language and proper technical terms. Provide comprehensive explanations with examples and references.',
    ),
    EducationLevel(
      id: 'university',
      nameEn: 'University (Bachelor/Master)',
      nameUr: 'یونیورسٹی (بیچلر/ماسٹر)',
      namePs: 'پوهنتون (بیچلر/ماسټر)',
      systemPromptHint: 'The student is at university level. Use advanced academic and professional language. Provide in-depth analysis, research-level explanations, and cite relevant theories or frameworks.',
    ),
  ];
}
