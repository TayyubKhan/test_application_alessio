import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
