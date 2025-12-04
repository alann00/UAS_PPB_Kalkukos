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

  final String apiBase = "http://10.50.216.245/flutter_uas_kalkukos";

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
          ),
        ],
      ),
    );

    if (result == "refresh") loadData();
  }

  // =====================================================
  // TextField Form
  // =====================================================
  Widget inputForm(TextEditingController c, String label,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : [],
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
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          "Pengeluaran",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: addPengeluaran,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: pengeluaran.length,
                  itemBuilder: (context, i) {
                    final x = pengeluaran[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// LEFT SIDE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x["nama_pengeluaran"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.category,
                                      color: Colors.deepPurple, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    x["kategori"],
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    x["tanggal_transaksi"],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          /// RIGHT SIDE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rp ${x['jumlah_biaya']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent, size: 26),
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
