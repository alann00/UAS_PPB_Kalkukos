import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List pengeluaran = [];
  List pengeluaranAsli = []; // untuk semua data
  bool loading = true;

  final String apiBase = "http://10.50.216.245/flutter_uas_kalkukos";

  List<String> bulanList = [
    "Semua",
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  String bulanDipilih = "Semua";

  @override
  void initState() {
    super.initState();
    loadRiwayat();
  }

  Future<void> loadRiwayat() async {
    setState(() => loading = true);

    try {
      final response =
          await http.get(Uri.parse("$apiBase/get_pengeluaran.php"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          pengeluaranAsli = data;
          pengeluaran = data;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      print("ERROR RIWAYAT: $e");
    }
  }

  void filterByBulan(String bulanNama) {
    if (bulanNama == "Semua") {
      setState(() => pengeluaran = pengeluaranAsli);
      return;
    }

    final idx = bulanList.indexOf(bulanNama);
    if (idx <= 0) return;

    final kode = idx.toString().padLeft(2, '0');

    List filtered = pengeluaranAsli.where((x) {
      final tanggal = x["tanggal_transaksi"].toString();
      if (tanggal.length >= 7) {
        return tanggal.substring(5, 7) == kode;
      }
      return false;
    }).toList();

    setState(() {
      pengeluaran = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Riwayat Pengeluaran",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true, // ⬅️ judul ke tengah
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: DropdownButtonFormField(
                    value: bulanDipilih,
                    decoration: InputDecoration(
                      labelText: "Filter berdasarkan Bulan",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: bulanList
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(b),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => bulanDipilih = value!);
                      filterByBulan(value!);
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: pengeluaran.isEmpty
                      ? const Center(
                          child: Text(
                            "Tidak ada riwayat pada bulan ini",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: pengeluaran.length,
                          itemBuilder: (context, index) {
                            final x = pengeluaran[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      x["nama_pengeluaran"],
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${x['kategori']} • ${x['tanggal_transaksi']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Rp ${x['jumlah_biaya']}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
