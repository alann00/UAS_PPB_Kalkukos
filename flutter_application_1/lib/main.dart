import 'package:flutter/material.dart';
import 'navbar.dart';

void main() {
  runApp(const KalkuKosan());
}

class KalkuKosan extends StatelessWidget {
  const KalkuKosan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "KalkuKosan",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color.fromARGB(186, 104, 58, 183),          // warna utama ungu elegan
          secondary: Colors.deepPurpleAccent,  // aksen
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // abu-abu muda bersih
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade600,
          elevation: 3,
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Poppins',
      ),
      home: const Navbar(), // halaman pertama masuk ke navbar
    );
  }
}