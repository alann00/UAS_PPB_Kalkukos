import 'package:flutter/material.dart';
import 'database_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final db = DatabaseService();
  List<Map<String, dynamic>> riwayat = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    var data = await db.getRiwayat();
    // Mengurutkan berdasarkan tanggal descending (baru → lama)
    data.sort((a, b) => b["tanggal"].compareTo(a["tanggal"]));
    setState(() => riwayat = data);
  }

  Color tipeWarna(String tipe) {
    if (tipe.toLowerCase() == "pengeluaran") return Colors.redAccent;
    return Colors.blueAccent; // tagihan yang sudah dibayar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: riwayat.isEmpty
          ? const Center(child: Text("Belum ada riwayat transaksi"))
          : ListView.builder(
              itemCount: riwayat.length,
              itemBuilder: (context, i) {
                var item = riwayat[i];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tipeWarna(item["tipe"]),
                      child: Text(item["tipe"][0].toUpperCase()),
                    ),
                    title: Text(item["nama"]),
                    subtitle: Text("Rp ${item["nominal"]}  |  ${item["tanggal"]}"),
                  ),
                );
              },
            ),
    );
  }
}
