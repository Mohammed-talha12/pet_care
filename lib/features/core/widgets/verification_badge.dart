import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({super.key, required this.isVerified, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Tooltip(
        message: 'Verified Professional',
        child: Icon(
          Icons.verified,
          color: Colors.blue, // Official verification color
          size: size,
        ),
      ),
    );
  }
}