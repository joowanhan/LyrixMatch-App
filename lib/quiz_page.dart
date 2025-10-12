// quiz_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:temp/constants.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> quizData;

  const QuizPage({super.key, required this.quizData});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _isLoading = false;
  int currentIndex = 0;
  int correctCount = 0;
  TextEditingController answerController = TextEditingController();

  void checkAnswer() {
    String userAnswer = answerController.text.trim().toLowerCase();
    String correctAnswer =
        widget.quizData[currentIndex]['title'].toString().trim().toLowerCase();

    bool isCorrect = userAnswer == correctAnswer;
    if (isCorrect) {
      setState(() => correctCount++);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? '정답!' : '오답'),
        content: Text(isCorrect
            ? '정답입니다.'
            : '틀렸습니다. 정답은 "${widget.quizData[currentIndex]['title']}"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              nextQuiz();
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  void nextQuiz() {
    if (currentIndex < widget.quizData.length - 1) {
      setState(() {
        currentIndex++;
        answerController.clear();
      });
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {
          'correct': correctCount,
          'total': widget.quizData.length,
        },
      );
    }
  }

  void showWordCloud(String title) async {
    setState(() {
      _isLoading = true;
    });

    // 로딩 다이얼로그 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wordcloud?title=$title'),
      );

      Navigator.pop(context); // 로딩 인디케이터 닫기

      if (response.statusCode == 200) {
        final imagePath = jsonDecode(response.body)['image_path'];
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'wordcloud',
                    child: Image.network(
                      '$baseUrl/$imagePath',
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("닫기"),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        print("워드클라우드 요청 실패: ${response.body}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("에러"),
            content: const Text("워드클라우드를 불러올 수 없습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 로딩 인디케이터 닫기
      print("요청 중 오류 발생: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizData[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎧 LyrixMatch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('문제 ${currentIndex + 1} / ${widget.quizData.length}',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ...quiz['summary']
                .split('\n')
                .map<Widget>((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(line, style: const TextStyle(fontSize: 16)),
                    ))
                .toList(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children: quiz['keywords']
                  .map<Widget>((kw) => Chip(label: Text(kw)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: '노래 제목 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: checkAnswer,
              child: const Text('정답 제출'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => showWordCloud(quiz['title']),
              child: const Text('힌트(워드클라우드) 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
