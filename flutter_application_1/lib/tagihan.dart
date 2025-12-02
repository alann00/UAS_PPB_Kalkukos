import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  _TagihanPageState createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  final TextEditingController nominalC = TextEditingController();
  final TextEditingController tempoC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final TextEditingController customJenisC = TextEditingController();

  List<Map<String, dynamic>> listTagihan = [];
  final DatabaseService db = DatabaseService();
  bool loading = true;

  // Jenis tagihan yang umum untuk anak kost
  final List<Map<String, dynamic>> jenisTagihan = [
    {'nama': 'Wifi/Internet', 'icon': Icons.wifi},
    {'nama': 'Listrik', 'icon': Icons.bolt},
    {'nama': 'Air', 'icon': Icons.water_drop},
    {'nama': 'Laundry', 'icon': Icons.local_laundry_service},
    {'nama': 'Gas', 'icon': Icons.local_fire_department},
    {'nama': 'Sewa Kos', 'icon': Icons.home},
    {'nama': 'Lainnya', 'icon': Icons.more_horiz},
  ];
  
  String? selectedJenis;
  IconData selectedIcon = Icons.receipt_long;
  bool isCustomInput = false;

  // Dashboard stats
  int totalTagihan = 0;
  int tagihanLunas = 0;
  int tagihanBelum = 0;
  double totalNominalBelum = 0;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    nominalC.dispose();
    tempoC.dispose();
    catatanC.dispose();
    customJenisC.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() => loading = true);
    
    try {
      var data = await db.getTagihan();
      
      // Hitung statistik
      int lunas = 0;
      int belum = 0;
      double nominalBelum = 0;
      
      for (var item in data) {
        if (item['status'] == 1) {
          lunas++;
        } else {
          belum++;
          nominalBelum += (item['nominal'] ?? 0);
        }
      }
      
      setState(() {
        listTagihan = List<Map<String, dynamic>>.from(data);
        totalTagihan = data.length;
        tagihanLunas = lunas;
        tagihanBelum = belum;
        totalNominalBelum = nominalBelum;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> tambahTagihan() async {
    String namaTagihan = isCustomInput ? customJenisC.text : (selectedJenis ?? '');
    
    if (namaTagihan.isEmpty || nominalC.text.isEmpty || tempoC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi Jenis, Nominal, dan Tanggal Jatuh Tempo!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await db.insertTagihan({
      "nama_tagihan": namaTagihan,
      "nominal": double.tryParse(nominalC.text) ?? 0,
      "tanggal_jatuh_tempo": tempoC.text,
      "status": 0,
    });

    // Reset form
    nominalC.clear();
    tempoC.clear();
    catatanC.clear();
    customJenisC.clear();
    selectedJenis = null;
    selectedIcon = Icons.receipt_long;
    isCustomInput = false;
    
    getData();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Tagihan berhasil ditambahkan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> toggleStatusBayar(int id, int currentStatus) async {
    int newStatus = currentStatus == 1 ? 0 : 1;
    await db.setStatusTagihan(id, newStatus == 1);
    getData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 1 ? '✓ Ditandai sudah dibayar' : 'Ditandai belum dibayar'),
        backgroundColor: newStatus == 1 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> hapusTagihan(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tagihan?'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteTagihan(id);
      getData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tagihan berhasil dihapus')),
      );
    }
  }

  Future<void> pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepPurple,
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        tempoC.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void showFormTambah() {
    // Reset state
    selectedJenis = null;
    selectedIcon = Icons.receipt_long;
    isCustomInput = false;
    nominalC.clear();
    tempoC.clear();
    catatanC.clear();
    customJenisC.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tambah Tagihan Bulanan",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 1. JENIS TAGIHAN (Wajib)
                  const Text(
                    "Jenis Tagihan *",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: jenisTagihan.map((jenis) {
                      bool isSelected = selectedJenis == jenis['nama'];
                      bool isLainnya = jenis['nama'] == 'Lainnya';
                      
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isLainnya) {
                              // Aktifkan input custom
                              isCustomInput = true;
                              selectedJenis = null;
                            } else {
                              selectedJenis = jenis['nama'];
                              selectedIcon = jenis['icon'];
                              isCustomInput = false;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: (isSelected || (isLainnya && isCustomInput))
                                ? Colors.deepPurple 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isSelected || (isLainnya && isCustomInput))
                                  ? Colors.deepPurple 
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                jenis['icon'],
                                size: 20,
                                color: (isSelected || (isLainnya && isCustomInput))
                                    ? Colors.white 
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                jenis['nama'],
                                style: TextStyle(
                                  color: (isSelected || (isLainnya && isCustomInput))
                                      ? Colors.white 
                                      : Colors.grey.shade700,
                                  fontWeight: (isSelected || (isLainnya && isCustomInput))
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Input custom jika pilih "Lainnya"
                  if (isCustomInput) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customJenisC,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Masukkan jenis tagihan...",
                        prefixIcon: const Icon(Icons.edit_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 2. JUMLAH BIAYA (Wajib)
                  const Text(
                    "Jumlah Biaya *",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nominalC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "Contoh: 150000",
                      prefixIcon: const Icon(Icons.payments_outlined),
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. TANGGAL JATUH TEMPO (Wajib)
                  const Text(
                    "Tanggal Jatuh Tempo *",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tempoC,
                    readOnly: true,
                    onTap: pilihTanggal,
                    decoration: InputDecoration(
                      hintText: "Pilih tanggal",
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. CATATAN TAMBAHAN (Opsional)
                  const Text(
                    "Catatan Tambahan (opsional)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: catatanC,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Contoh: Tagihan bulan Desember, sudah termasuk biaya pemasangan",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Icon(Icons.note_outlined),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: tambahTagihan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Simpan Tagihan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int sisaHari(String tanggal) {
    final now = DateTime.now();
    final due = DateTime.parse(tanggal);
    return due.difference(now).inDays;
  }

  Color getStatusColor(int status, String tanggal) {
    if (status == 1) return Colors.green;
    int sisa = sisaHari(tanggal);
    if (sisa < 0) return Colors.red;
    if (sisa <= 3) return Colors.orange;
    return Colors.blue;
  }

  String getStatusText(int status, String tanggal) {
    if (status == 1) return "Lunas";
    int sisa = sisaHari(tanggal);
    if (sisa < 0) return "Terlambat ${sisa.abs()} hari";
    if (sisa == 0) return "Jatuh tempo hari ini!";
    return "$sisa hari lagi";
  }

  IconData getIconByName(String nama) {
    var jenis = jenisTagihan.firstWhere(
      (j) => j['nama'] == nama,
      orElse: () => {'nama': 'Lainnya', 'icon': Icons.receipt_long},
    );
    return jenis['icon'];
  }

  Widget buildDashboardCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
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
      appBar: AppBar(
        title: const Text("Tagihan Bulanan"),
        elevation: 0,
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showFormTambah,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text("Tagihan Baru"),
      ),
      
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
              children: [
                // Dashboard Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📊 Ringkasan Tagihan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: buildDashboardCard(
                              "Total Tagihan",
                              "$totalTagihan",
                              Icons.receipt_long,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildDashboardCard(
                              "Sudah Lunas",
                              "$tagihanLunas",
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: buildDashboardCard(
                              "Belum Bayar",
                              "$tagihanBelum",
                              Icons.pending,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildDashboardCard(
                              "Sisa Tagihan",
                              "Rp ${NumberFormat('#,###', 'id_ID').format(totalNominalBelum)}",
                              Icons.money_off,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // List Tagihan
                Expanded(
                  child: listTagihan.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, 
                                  size: 80, 
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada tagihan",
                                style: TextStyle(
                                  fontSize: 18, 
                                  color: Colors.grey.shade600
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap tombol + untuk menambah tagihan",
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: Colors.grey.shade500
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: listTagihan.length,
                          itemBuilder: (context, i) {
                            var item = listTagihan[i];
                            int status = item['status'] ?? 0;
                            String tanggal = item['tanggal_jatuh_tempo'];
                            String namaTagihan = item['nama_tagihan'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            getIconByName(namaTagihan),
                                            color: Colors.deepPurple,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                namaTagihan,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Rp ${NumberFormat('#,###', 'id_ID').format(item['nominal'])}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, 
                                                      size: 14, 
                                                      color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('dd MMM yyyy').format(DateTime.parse(tanggal)),
                                                    style: TextStyle(
                                                      fontSize: 13, 
                                                      color: Colors.grey.shade600
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => hapusTagihan(item['id'], namaTagihan),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          tooltip: 'Hapus tagihan',
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(status, tanggal),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            getStatusText(status, tanggal),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              status == 1 ? "Sudah dibayar" : "Belum dibayar",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: status == 1 ? Colors.green : Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: status == 1,
                                              onChanged: (value) => toggleStatusBayar(item['id'], status),
                                              activeColor: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ],
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