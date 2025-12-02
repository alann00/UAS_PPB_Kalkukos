import 'package:flutter/material.dart';
import 'database_service.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController kategoriC = TextEditingController();
  final TextEditingController jumlahC = TextEditingController();

  List<Map> dataPengeluaran = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  /// 🔹 Ambil data dari database
  Future<void> getData() async {
    final db = DatabaseService();
    var hasil = await db.getPengeluaran();
    setState(() {
      dataPengeluaran = hasil;
      loading = false;
    });
  }

  /// 🔹 Tambah pengeluaran
  Future<void> tambahPengeluaran() async {
    if (namaC.text.isEmpty || jumlahC.text.isEmpty) return;

    final db = DatabaseService();
    await db.addPengeluaran(
      namaC.text,
      kategoriC.text.isEmpty ? "-" : kategoriC.text,
      double.parse(jumlahC.text),
    );

    namaC.clear();
    kategoriC.clear();
    jumlahC.clear();
    getData(); // refresh list

    Navigator.pop(context); // tutup form dialog
  }

  /// 🔹 Dialog input form
  void openForm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Tambah Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          height: 230,
          child: Column(
            children: [
              inputForm(namaC, "Nama pengeluaran"),
              const SizedBox(height: 8),
              inputForm(kategoriC, "Kategori (opsional)"),
              const SizedBox(height: 8),
              inputForm(jumlahC, "Jumlah (Rp)", number: true),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: tambahPengeluaran,
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Widget input TextField elegan
  Widget inputForm(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengeluaran"),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: openForm,
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : dataPengeluaran.isEmpty
              ? const Center(
                  child: Text("Belum ada pengeluaran",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dataPengeluaran.length,
                  itemBuilder: (context, i) {
                    var x = dataPengeluaran[i];
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x['nama'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("${x['kategori']}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text("${x['tanggal']}",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                          Text(
                            "Rp ${x['jumlah']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.deepPurple),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
