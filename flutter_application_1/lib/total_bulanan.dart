import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';

class TotalBulananPage extends StatefulWidget {
  const TotalBulananPage({super.key});

  @override
  State<TotalBulananPage> createState() => _TotalBulananPageState();
}

class _TotalBulananPageState extends State<TotalBulananPage> {
  final db = DatabaseService();

  double totalPengeluaran = 0;
  double totalTagihanTerbayar = 0;
  double totalTagihanBelum = 0;

  @override
  void initState() {
    super.initState();
    hitungTotal();
  }

  Future<void> hitungTotal() async {
    var pengeluaran = await db.getPengeluaran();
    var tagihan = await db.getTagihan();

    // filter bulan ini
    String bulanIni = DateFormat('yyyy-MM').format(DateTime.now());

    pengeluaran.forEach((item) {
      if (item["tanggal"].startsWith(bulanIni)) {
        totalPengeluaran += item["jumlah"];
      }
    });

    tagihan.forEach((item) {
      if (item["tanggal_jatuh_tempo"].startsWith(bulanIni)) {
        if (item["status"] == 1) {
          totalTagihanTerbayar += item["nominal"];
        } else {
          totalTagihanBelum += item["nominal"];
        }
      }
    });

    setState(() {});
  }

  Widget cardItem(String judul, double nilai, Color warna) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text("Rp $nilai", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Total Bulanan")),
      body: Column(
        children: [
          cardItem("Total Pengeluaran Bulan Ini", totalPengeluaran, Colors.redAccent),
          cardItem("Tagihan Sudah Dibayar", totalTagihanTerbayar, Colors.green),
          cardItem("Tagihan Belum Dibayar", totalTagihanBelum, Colors.orangeAccent),
        ],
      ),
    );
  }
}
