import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/velocity_theme.dart';

class PremiumFilesPage extends StatelessWidget {
  const PremiumFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Files\nComing Soon',
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
