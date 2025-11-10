import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.JPG',
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.sports_soccer,
            color: Colors.grey,
            size: 48,
          ),
        );
      },
    );
  }
}

class AppLogoSmall extends StatelessWidget {
  const AppLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 32,
      height: 32,
    );
  }
}

class AppLogoMedium extends StatelessWidget {
  const AppLogoMedium({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 64,
      height: 64,
    );
  }
}

class AppLogoLarge extends StatelessWidget {
  const AppLogoLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 120,
      height: 120,
    );
  }
}

