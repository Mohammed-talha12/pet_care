import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
  backgroundColor: Theme.of(context).primaryColor,
  foregroundColor: Colors.white,
  // Fix: Use RoundedRectangleBorder to apply the radius
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}