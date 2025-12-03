<?php
header('Content-Type: application/json');
include "config.php";

$query = mysqli_query($conn, "SELECT * FROM pengeluaran ORDER BY id DESC");

$data = [];
while ($row = mysqli_fetch_assoc($query)) {
    $data[] = [
        "id" => $row["id"],
        "nama_pengeluaran" => $row["nama_pengeluaran"],
        "jumlah_biaya" => $row["jumlah_biaya"],
        "kategori" => $row["kategori"],
        "tanggal_transaksi" => $row["tanggal_transaksi"]
    ];
}

echo json_encode($data);
?>
