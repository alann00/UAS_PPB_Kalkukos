import 'package:flutter/material.dart';
import 'database_service.dart';
import 'dart:async';

class PengingatPage extends StatefulWidget {
  const PengingatPage({super.key});

  @override
  State<PengingatPage> createState() => _PengingatPageState();
}

class _PengingatPageState extends State<PengingatPage> {
  List<Map<String, dynamic>> tagihan = [];
  final db = DatabaseService(); // ⬅ tanpa instance, sesuai struktur kamu

  @override
  void initState() {
    super.initState();
    loadTagihan();
  }

  Future<void> loadTagihan() async {
    var data = await db.getTagihan();

    // hanya ambil tagihan yg belum dibayar
    setState(() {
      tagihan = data.where((t) => t["status"] == 0).toList();
    });
  }

  /// Hitung sisa hari menuju jatuh tempo
  int hitungHari(String tanggal) {
    final now = DateTime.now();
    final due = DateTime.parse(tanggal);
    return due.difference(now).inDays;
  }

  /// tombol “Sudah Bayar”
  Future<void> bayarTagihan(int id) async {
    await db.setStatusTagihan(id, true);
    loadTagihan(); // refresh list
  }

  /// warna badge sesuai urgensi
  Color warnaHari(int sisa) {
    if (sisa <= 2) return Colors.redAccent;
    if (sisa <= 6) return Colors.orangeAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengingat Tagihan")),

      body: tagihan.isEmpty
          ? const Center(
              child: Text(
                "🎉 Semua tagihan sudah beres!",
                style: TextStyle(fontSize: 17),
              ),
            )
          : ListView.builder(
              itemCount: tagihan.length,
              itemBuilder: (context, i) {
                var item = tagihan[i];
                int sisa = hitungHari(item["tanggal_jatuh_tempo"]);

                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                    title: Text(item["nama_tagihan"],
                        style: const TextStyle(fontWeight: FontWeight.bold)),

                    subtitle: Text("Jatuh tempo: ${item["tanggal_jatuh_tempo"]}"),

                    leading: CircleAvatar(
                      backgroundColor: warnaHari(sisa),
                      child: Text(
                        sisa.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    trailing: ElevatedButton(
                      onPressed: () => bayarTagihan(item["id"]),
                      child: const Text("Sudah Bayar"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
