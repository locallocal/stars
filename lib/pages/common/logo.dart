import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildProviderLogo(BuildContext context, String avatar, String provider, double size) {
    if (avatar.isNotEmpty) {
      return Image.file(
        File(avatar),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    
    final String providerLower = provider.toLowerCase();
    if (providerLower == 'custom' || providerLower == '') {
      return Icon(
        Icons.smart_toy_rounded,
        size: size,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    try {
      return SvgPicture.asset(
        'assets/images/providers/$providerLower.svg',
        width: size,
        height: size,
        placeholderBuilder: (context) => Icon(
          Icons.smart_toy_rounded,
          size: size,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } catch (e) {
      return Image.asset(
        'assets/images/providers/$providerLower.png',
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.smart_toy_rounded,
            size: size,
            color: Theme.of(context).colorScheme.onSurface,
          );
        },
      );
    }
  }