import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_tutor/main.dart';
import 'package:ai_tutor/models/message.dart';
import 'package:ai_tutor/models/subject.dart';
import 'package:ai_tutor/models/education_level.dart';
import 'package:ai_tutor/providers/app_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Tests', () {
    test('Message model serializes and deserializes correctly', () {
      final msg = Message(
        content: 'Hello, what is gravity?',
        role: MessageRole.user,
      );

      final json = msg.toJson();
      expect(json['content'], 'Hello, what is gravity?');
      expect(json['role'], 'user');
      expect(json['isError'], false);

      final fromJson = Message.fromJson(json);
      expect(fromJson.content, msg.content);
      expect(fromJson.role, MessageRole.user);
      expect(fromJson.isError, false);
    });

    test('Subject data contains 6 core subjects with trilingual translations', () {
      expect(SubjectData.subjects.length, 6);

      final math = SubjectData.subjects.firstWhere((s) => s.id == 'mathematics');
      expect(math.getName('en'), 'Mathematics');
      expect(math.getName('ur'), 'ریاضی');
      expect(math.getName('ps'), 'ریاضی');

      final cs = SubjectData.subjects.firstWhere((s) => s.id == 'computer_science');
      expect(cs.getName('en'), 'Computer Science');
      expect(cs.getName('ur'), 'کمپیوٹر سائنس');
      expect(cs.getName('ps'), 'کمپیوټر ساینس');
    });

    test('EducationLevel data contains 5 levels from Primary to University', () {
      expect(EducationLevelData.levels.length, 5);

      final primary = EducationLevelData.levels[0];
      expect(primary.id, 'primary');
      expect(primary.systemPromptHint.contains('primary school'), true);

      final university = EducationLevelData.levels[4];
      expect(university.id, 'university');
      expect(university.systemPromptHint.contains('university'), true);
    });
  });

  group('AppProvider Tests', () {
    test('Initializes with default English and high school level', () {
      final provider = AppProvider();
      expect(provider.languageCode, 'en');
      expect(provider.educationLevelId, 'high');
      expect(provider.isRtl, false);
    });

    test('RTL is correctly enabled for Urdu and Pashto', () async {
      final provider = AppProvider();
      expect(provider.isRtl, false);

      await provider.setLanguage('ur');
      expect(provider.isRtl, true);

      await provider.setLanguage('ps');
      expect(provider.isRtl, true);

      await provider.setLanguage('en');
      expect(provider.isRtl, false);
    });

    test('Demo message handling adds user and assistant response', () async {
      final provider = AppProvider();
      expect(provider.messages.isEmpty, true);

      await provider.sendMessage('What is 2+2?');
      expect(provider.messages.length, 2);
      expect(provider.messages[0].role, MessageRole.user);
      expect(provider.messages[0].content, 'What is 2+2?');
      expect(provider.messages[1].role, MessageRole.assistant);
      expect(provider.messages[1].content.contains('Demo'), true);
    });

    test('Clear conversation removes all messages', () async {
      final provider = AppProvider();
      await provider.sendMessage('Test');
      expect(provider.messages.isNotEmpty, true);

      provider.clearConversation();
      expect(provider.messages.isEmpty, true);
    });
  });

  group('Widget Tests', () {
    testWidgets('App renders Home Screen with branding and navigation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AiTutorApp());
      await tester.pumpAndSettle();

      // Verify branding
      expect(find.text('AI Tutor'), findsWidgets);

      // Verify Navigation bar items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Subjects header and first subject
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('Bottom navigation switches to Chat and Settings', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AiTutorApp());
      await tester.pumpAndSettle();

      // Tap Chat nav item
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Chat screen elements should now be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Tap Settings nav item
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Settings screen elements
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Education Level'), findsOneWidget);
    });
  });
}
