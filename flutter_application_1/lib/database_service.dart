import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySqlConnection? _conn;

  // ============================
  // 🔌 CONNECT DATABASE
  // ============================
  Future<MySqlConnection> connect() async {
    if (_conn != null) return _conn!;
    
    final settings = ConnectionSettings(
      host: '10.22.131.201',
      port: 3306,
      user: 'root',
      password: '',
      db: 'db_kalkukosan',
    );

    _conn = await MySqlConnection.connect(settings);
    return _conn!;
  }

  // ============================
  // 💰 CRUD PENGELUARAN
  // ============================
  Future<int> addPengeluaran(String nama, String kategori, double jumlah) async {
    final db = await connect();
    var result = await db.query(
      "INSERT INTO pengeluaran (nama, kategori, jumlah, tanggal) VALUES (?, ?, ?, NOW())",
      [nama, kategori, jumlah],
    );

    await addRiwayat("pengeluaran", nama, jumlah);
    return result.insertId!;
  }

  Future<List<Map<String, dynamic>>> getPengeluaran() async {
    final db = await connect();
    var results = await db.query("SELECT * FROM pengeluaran ORDER BY tanggal DESC");

    return results.map((row) => {
      "id": row['id'],
      "nama": row['nama'],
      "kategori": row['kategori'],
      "jumlah": row['jumlah'],
      "tanggal": row['tanggal'],
    }).toList();
  }

  Future<void> deletePengeluaran(int id) async {
    final db = await connect();
    await db.query("DELETE FROM pengeluaran WHERE id = ?", [id]);
  }

  // ============================
  // 📄 CRUD TAGIHAN BULANAN
  // ============================
  Future<int> insertTagihan(Map<String, dynamic> data) async {
    final db = await connect();
    var res = await db.query(
      "INSERT INTO tagihan_bulanan (nama_tagihan, nominal, tanggal_jatuh_tempo, is_paid) VALUES (?, ?, ?, ?)",
      [
        data["nama_tagihan"],
        data["nominal"],
        data["tanggal_jatuh_tempo"],
        data["status"] ?? 0          // default = belum dibayar
      ],
    );

    return res.insertId!;
  }

  Future<List<Map<String, dynamic>>> getTagihan() async {
    final db = await connect();
    var rows = await db.query("SELECT * FROM tagihan_bulanan ORDER BY tanggal_jatuh_tempo ASC");

    return rows.map((row) => {
      "id": row["id"],
      "nama_tagihan": row["nama_tagihan"],
      "nominal": row["nominal"],
      "tanggal_jatuh_tempo": row["tanggal_jatuh_tempo"],
      "status": row["is_paid"],
    }).toList();
  }

  Future<void> deleteTagihan(int id) async {
    final db = await connect();
    await db.query("DELETE FROM tagihan_bulanan WHERE id = ?", [id]);
  }

  /// ⭐ UPDATE status bayar (dipakai di halaman pengingat)
  Future<void> setStatusTagihan(int id, bool isPaid) async {
    final db = await connect();
    await db.query(
      "UPDATE tagihan_bulanan SET is_paid = ? WHERE id = ?",
      [isPaid ? 1 : 0, id],
    );
  }

  // ============================
  // 📜 RIWAYAT TRANSAKSI
  // ============================
  Future<void> addRiwayat(String tipe, String nama, double nominal) async {
    final db = await connect();
    await db.query(
      "INSERT INTO riwayat_transaksi (tipe, nama, nominal, tanggal) VALUES (?, ?, ?, NOW())",
      [tipe, nama, nominal],
    );
  }

  Future<List<Map<String, dynamic>>> getRiwayat() async {
    final db = await connect();
    var r = await db.query("SELECT * FROM riwayat_transaksi ORDER BY tanggal DESC");

    return r.map((row) => {
      "id": row['id'],
      "tipe": row['tipe'],
      "nama": row['nama'],
      "nominal": row['nominal'],
      "tanggal": row['tanggal'],
    }).toList();
  }

  // ============================
  // 📊 TOTAL BULANAN
  // ============================
  Future<double> totalPengeluaranBulanIni() async {
    final db = await connect();
    var r = await db.query("""
      SELECT IFNULL(SUM(jumlah),0) as total 
      FROM pengeluaran 
      WHERE MONTH(tanggal) = MONTH(NOW()) AND YEAR(tanggal) = YEAR(NOW())
    """);
    return r.first['total'];
  }

  Future<double> totalTagihanDibayar() async {
    final db = await connect();
    var r = await db.query("""
      SELECT IFNULL(SUM(nominal),0) as total 
      FROM tagihan_bulanan 
      WHERE is_paid = 1 AND MONTH(tanggal_jatuh_tempo) = MONTH(NOW())
    """);
    return r.first['total'];
  }

  Future<double> totalBulananAkhir() async {
    return await totalPengeluaranBulanIni() + await totalTagihanDibayar();
  }
}
