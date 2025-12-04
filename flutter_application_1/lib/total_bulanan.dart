import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class TotalBulananPage extends StatefulWidget {
  const TotalBulananPage({super.key});

  @override
  State<TotalBulananPage> createState() => _TotalBulananPageState();
}

class _TotalBulananPageState extends State<TotalBulananPage> {
  double pengeluaran = 0;
  double tagihanDibayar = 0;
  double totalAkhir = 0;

  bool loading = true;

  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> loadData() async {
    try {
      final url = Uri.parse(
          "http://10.50.216.245/flutter_uas_kalkukos/total_bulanan.php");

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          pengeluaran =
              double.tryParse(data["pengeluaran_bulan_ini"].toString()) ?? 0.0;
          tagihanDibayar =
              double.tryParse(data["tagihan_dibayar"].toString()) ?? 0.0;
          totalAkhir =
              double.tryParse(data["total_bulanan"].toString()) ?? 0.0;

          loading = false;
        });
      } else {
        throw Exception("Gagal load data");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      loadData();
    });
  }

  Widget cardItem({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  formatter.format(value),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Total Bulanan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true, // ⬅️ agar judul ke tengah
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              color: Colors.deepPurple,
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),

                  // Header bulan
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        "Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Card pengeluaran
                  cardItem(
                    title: "Pengeluaran Bulan Ini",
                    value: pengeluaran,
                    icon: Icons.money_off,
                    color: Colors.redAccent,
                  ),

                  // Card tagihan dibayar
                  cardItem(
                    title: "Tagihan Dibayar",
                    value: tagihanDibayar,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  // TOTAL AKHIR
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade600,
                          Colors.deepPurple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TOTAL KESELURUHAN",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatter.format(totalAkhir),
                                style: const TextStyle(
                                    fontSize: 26,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }
}
