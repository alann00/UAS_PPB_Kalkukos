import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Tagihan {
  final int id;
  final String nama;
  final int jumlah;
  final DateTime tanggal;
  int status; // 0 = belum, 1 = lunas

  Tagihan({
    required this.id,
    required this.nama,
    required this.jumlah,
    required this.tanggal,
    required this.status,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) {
    return Tagihan(
      id: int.parse(json['id'].toString()),
      nama: json['nama_tagihan'],
      jumlah: int.parse(json['nominal'].toString()),
      tanggal: DateTime.parse(json['tanggal_jatuh_tempo']),
      status: int.parse(json['is_paid'].toString()),
    );
  }
}

class TagihanPage extends StatefulWidget {
  const TagihanPage({Key? key}) : super(key: key);

  @override
  _TagihanPageState createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  final currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final String baseUrl = "http://10.50.216.245/flutter_uas_kalkukos";
  List<Tagihan> list = [];
  bool loading = true;

  int overdueCount = 0;
  int dueSoonCount = 0;
  final int dueSoonDays = 3;

  @override
  void initState() {
    super.initState();
    fetchTagihan();
  }

  int daysUntil(DateTime tanggal) {
    final now = DateTime.now();
    final diff = tanggal.difference(DateTime(now.year, now.month, now.day));
    return diff.inDays;
  }

  Future<void> fetchTagihan() async {
    setState(() => loading = true);

    try {
      final res = await http.get(Uri.parse("$baseUrl/get_tagihan.php"));
      final data = json.decode(res.body);
      List<Tagihan> temp = [];

      for (var t in data["data"]) {
        temp.add(Tagihan.fromJson(t));
      }

      int over = 0;
      int soon = 0;
      for (var tg in temp) {
        if (tg.status == 0) {
          final d = daysUntil(tg.tanggal);
          if (d < 0) {
            over++;
          } else if (d <= dueSoonDays) {
            soon++;
          }
        }
      }

      setState(() {
        list = temp;
        overdueCount = over;
        dueSoonCount = soon;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("ERROR GET: $e");
    }
  }

  Future<void> addTagihan(String nama, int jumlah, String tanggal) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/add_tagihan.php"),
        body: {
          "nama_tagihan": nama,
          "nominal": jumlah.toString(),
          "tanggal_jatuh_tempo": tanggal,
        },
      );

      fetchTagihan();
    } catch (e) {
      print("ERROR ADD: $e");
    }
  }

  Future<void> deleteTagihan(int id) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/delete_tagihan.php"),
        body: {"id": id.toString()},
      );

      fetchTagihan();
    } catch (e) {
      print("ERROR DELETE: $e");
    }
  }

  Future<void> updateStatus(int id, int status) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/update_status.php"),
        body: {"id": id.toString(), "is_paid": status.toString()},
      );

      if (status == 1) {
        final tagihan = list.firstWhere((t) => t.id == id);

        final response = await http.post(
          Uri.parse("$baseUrl/add_pengeluaran.php"),
          body: {
            "nama_pengeluaran": "Pembayaran Tagihan: ${tagihan.nama}",
            "kategori": "Tagihan",
            "jumlah_biaya": tagihan.jumlah.toString(),
            "tanggal_transaksi":
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
          },
        );

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Gagal tambah ke riwayat: ${response.statusCode} ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      fetchTagihan();
    } catch (e) {
      print("ERROR UPDATE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  //  FORM TENGAH LAYAR
  // --------------------------------------------------------------------------
  void openAddModal() {
    final namaC = TextEditingController();
    final jumlahC = TextEditingController();
    DateTime? picked;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Tambah Tagihan",
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (ctx, setM) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaC,
                    decoration: const InputDecoration(labelText: "Nama Tagihan"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: jumlahC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(labelText: "Nominal (Rp)"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          picked == null
                              ? "Pilih tanggal"
                              : DateFormat('yyyy-MM-dd').format(picked!),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (p != null) setM(() => picked = p);
                        },
                        child: const Text("Pilih"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (namaC.text.isEmpty ||
                    jumlahC.text.isEmpty ||
                    picked == null) return;

                addTagihan(
                  namaC.text,
                  int.parse(jumlahC.text),
                  DateFormat('yyyy-MM-dd').format(picked!),
                );

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------

  Widget buildNotificationBanner() {
    if (overdueCount == 0 && dueSoonCount == 0) return const SizedBox.shrink();

    List<Widget> chips = [];
    if (overdueCount > 0) {
      chips.add(Chip(
        avatar: const Icon(Icons.error, color: Colors.white, size: 18),
        backgroundColor: Colors.red,
        label: Text("$overdueCount tagihan lewat",
            style: const TextStyle(color: Colors.white)),
      ));
    }
    if (dueSoonCount > 0) {
      chips.add(Chip(
        avatar: const Icon(Icons.schedule, color: Colors.white, size: 18),
        backgroundColor: Colors.orange,
        label: Text("$dueSoonCount mendekati jatuh tempo",
            style: const TextStyle(color: Colors.white)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) {
              final overdueList =
                  list.where((t) => t.status == 0 && daysUntil(t.tanggal) < 0);
              final soonList = list.where((t) =>
                  t.status == 0 &&
                  daysUntil(t.tanggal) >= 0 &&
                  daysUntil(t.tanggal) <= dueSoonDays);
              return AlertDialog(
                title: const Text("Pemberitahuan Tagihan"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overdueList.isNotEmpty) ...[
                        const Text("Tagihan Lewat:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...overdueList.map((t) => Text(
                            "- ${t.nama} (${DateFormat('dd MMM yyyy').format(t.tanggal)})")),
                        const SizedBox(height: 12),
                      ],
                      if (soonList.isNotEmpty) ...[
                        const Text("Mendekati Jatuh Tempo:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...soonList.map((t) {
                          final d = daysUntil(t.tanggal);
                          return Text("- ${t.nama} (dalam $d hari)");
                        }),
                      ],
                      if (overdueList.isEmpty && soonList.isEmpty)
                        const Text("Tidak ada pemberitahuan."),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"))
                ],
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(spacing: 8, runSpacing: 4, children: chips),
              ),
              const Icon(Icons.chevron_right, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }

  // UI --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Tagihan"),
        centerTitle: true, // ⬅ JUDUL TENGAH
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddModal,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
        backgroundColor: Colors.deepPurple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? const Center(child: Text("Belum ada tagihan"))
              : Column(
                  children: [
                    buildNotificationBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        itemBuilder: (c, i) {
                          final t = list[i];
                          final d = daysUntil(t.tanggal);

                          Color accentColor = Colors.deepPurple;
                          String badge = "";
                          if (t.status == 0) {
                            if (d < 0) {
                              accentColor = Colors.red;
                              badge = "Lewat";
                            } else if (d <= dueSoonDays) {
                              accentColor = Colors.orange;
                              badge = "Jatuh tempo dalam $d hari";
                            }
                          } else {
                            accentColor = Colors.green;
                            badge = "Lunas";
                          }

                          Widget? badgeChip;
                          if (badge.isNotEmpty) {
                            String chipLabel = badge;
                            if (badge.startsWith("Jatuh tempo")) {
                              chipLabel = d < 1 ? "Hari ini" : "Dalam $d hari";
                            }
                            if (badge == "Lewat") chipLabel = "Lewat";
                            if (badge == "Lunas") chipLabel = "Lunas";

                            badgeChip = Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                              child: Chip(
                                backgroundColor: accentColor,
                                label: Text(
                                  chipLabel,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          } else {
                            badgeChip = const SizedBox.shrink();
                          }

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, color: accentColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.nama,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold)),
                                            Text(currency.format(t.jumlah),
                                                style: TextStyle(color: accentColor)),
                                            Text(DateFormat('dd MMM yyyy').format(t.tanggal)),
                                          ],
                                        ),
                                      ),
                                      badgeChip,
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteTagihan(t.id),
                                      )
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.status == 1 ? "Lunas" : "Belum Lunas",
                                          style: TextStyle(
                                              color: t.status == 1
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (badge.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            badge,
                                            style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      Switch(
                                        value: t.status == 1,
                                        onChanged: (v) => updateStatus(t.id, v ? 1 : 0),
                                      ),
                                    ],
                                  )
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
