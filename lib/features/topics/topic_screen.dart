import 'package:flutter/material.dart';
import 'package:konfide/data/questions.dart';
import 'package:konfide/features/questions/question_screen.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfide'),
      ),
      body: ListView(
        children: const [
          TopicCard(
            title: 'Getting to know you',
            description: 'Questions for new acquaintances.',
            questions: getToKnowYouQuestions,
          ),
          TopicCard(
            title: 'Learning more',
            description: 'New insights into old friends and family.',
            questions: familyAndFriendsQuestions,
          ),
          TopicCard(
            title: 'Thought provoking',
            description: 'Designed to challenge your thinking.',
            questions: thoughtProvokingQuestions,
          ),
          TopicCard(
            title: 'Deeply personal',
            description: 'Uncomfortable for most people.',
            questions: deeplyPersonalQuestions,
          ),
        ],
      ),
    );
  }
}

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String title;
  final String description;
  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        minTileHeight: 80,
        minVerticalPadding: 24.0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => QuestionScreen(
                topic: title,
                questions: questions,
              ),
            ),
          );
        },
      ),
    );
  }
}
