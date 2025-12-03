import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  List pengeluaran = [];
  bool isLoading = true;

  final String apiBase = "http://192.168.18.48/flutter_uas_kalkukos";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =====================================================
  // GET DATA
  // =====================================================
  Future<void> loadData() async {
    setState(() => isLoading = true);

    final response = await http.get(Uri.parse("$apiBase/get_pengeluaran.php"));

    if (response.statusCode == 200) {
      setState(() {
        pengeluaran = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // =====================================================
  // DELETE DATA
  // =====================================================
  Future<void> deletePengeluaran(String id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Konfirmasi Hapus"),
        content: Text("Hapus '$nama'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await http.post(
        Uri.parse("$apiBase/delete_pengeluaran.php"),
        body: {"id": id},
      );

      loadData();
    }
  }

  // =====================================================
  // ADD DATA
  // =====================================================
  Future<void> addPengeluaran() async {
    TextEditingController namaC = TextEditingController();
    TextEditingController jumlahC = TextEditingController();
    TextEditingController kategoriC = TextEditingController();

    DateTime? pickedDate;

    final result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Tambah Pengeluaran",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          height: 260,
          child: Column(
            children: [
              inputForm(namaC, "Nama pengeluaran"),
              const SizedBox(height: 8),
              inputForm(kategoriC, "Kategori"),
              const SizedBox(height: 8),
              inputForm(jumlahC, "Jumlah (Rp)", number: true),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (dt != null) pickedDate = dt;
                },
                child: const Text("Pilih Tanggal",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () async {
              if (namaC.text.isEmpty ||
                  jumlahC.text.isEmpty ||
                  kategoriC.text.isEmpty ||
                  pickedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Semua field wajib diisi")),
                );
                return;
              }

              await http.post(
                Uri.parse("$apiBase/add_pengeluaran.php"),
                body: {
                  "nama_pengeluaran": namaC.text,
                  "jumlah_biaya": jumlahC.text,
                  "kategori": kategoriC.text,
                  "tanggal_transaksi": pickedDate!.toString().substring(0, 10),
                },
              );

              Navigator.pop(context, "refresh");
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    if (result == "refresh") loadData();
  }

  // =====================================================
  // TextField Form (dengan digitsOnly)
  // =====================================================
  Widget inputForm(TextEditingController c, String label,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters:
          number ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengeluaran"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: addPengeluaran,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : pengeluaran.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada pengeluaran",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pengeluaran.length,
                  itemBuilder: (context, i) {
                    final x = pengeluaran[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LEFT
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x["nama_pengeluaran"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                x["kategori"],
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                x["tanggal_transaksi"],
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),

                          // RIGHT — jumlah + icon hapus
                          Column(
                            children: [
                              Text(
                                "Rp ${x['jumlah_biaya']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deletePengeluaran(
                                  x["id"].toString(),
                                  x["nama_pengeluaran"],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
