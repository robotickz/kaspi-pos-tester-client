import 'package:flutter/material.dart';

class MyButtonWidget extends StatelessWidget {
  final String textButton;
  final Color bg;
  final dynamic fn;
  const MyButtonWidget({
    super.key,
    required this.textButton,
    required this.fn,
    this.bg = Colors.deepOrange,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: fn,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: Text(
          textButton,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
