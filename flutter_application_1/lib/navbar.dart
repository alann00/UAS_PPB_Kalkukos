import 'package:flutter/material.dart';

// Import halaman utama
import 'pengeluaran.dart';
import 'tagihan.dart';
import 'riwayat.dart';
import 'total_bulanan.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int index = 0;

  /// Halaman yang ditampilkan saat navbar diklik
  final List<Widget> pages = [
    PengeluaranPage(),
    TagihanPage(),
    RiwayatPage(),
    TotalBulananPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai index navbar
      body: pages[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        iconSize: 26,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_rounded),
            label: "Pengeluaran",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: "Tagihan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "Riwayat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Total",
          ),
        ],
      ),
    );
  }
}
