import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int correct = args['correct'] ?? 0;
    final int total = args['total'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("결과")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$total 문제 중 $correct개 정답!',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
              child: const Text("초기화면으로 가기"),
            ),
          ],
        ),
      ),
    );
  }
}
