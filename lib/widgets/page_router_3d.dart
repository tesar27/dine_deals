import 'package:flutter/material.dart';

class PageRouteWith3DTransition extends PageRouteBuilder {
  final Widget page;

  PageRouteWith3DTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                double value = tween.evaluate(animation);
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(value * 3.14 / 2), // rotate
                  alignment: Alignment.center,
                  child: child,
                );
              },
            );
          },
        );
}
