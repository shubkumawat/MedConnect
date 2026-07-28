import 'package:flutter/material.dart';

class CustomBottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Start from the top-left corner
    path.lineTo(0, 0);

    // Draw a line down to the bottom left
    path.lineTo(51, size.height - 50); // Adjust height as needed for the curve

    // Create a curved path at the bottom
    path.quadraticBezierTo(
      size.width / 2, size.height + 10, // Control point and end point of the curve
      size.width, size.height - 10, // Curve back to the bottom right
    );

    // Draw a line back to the top-right corner
    path.lineTo(size.width, 31);

    path.close(); // Close the path

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
