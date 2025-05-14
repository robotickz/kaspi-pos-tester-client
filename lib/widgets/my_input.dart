import 'package:flutter/material.dart';

class MyInputWidget extends StatelessWidget {
  final String inputName;
  final TextEditingController textEditingController;
  final int maxLines;
  const MyInputWidget({
    super.key,
    required this.inputName,
    required this.textEditingController,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        scrollPadding: const EdgeInsets.all(96),
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          labelText: inputName,
          errorStyle: const TextStyle(color: Colors.red),
          labelStyle: const TextStyle(color: Colors.black87),
          floatingLabelStyle: const TextStyle(color: Colors.black),
          enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 0, color: Colors.transparent),
          ),
          focusedBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 0, color: Colors.transparent),
          ),
          errorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 0, color: Colors.black),
          ),
        ),
        controller: textEditingController,
      ),
    );
  }
}
