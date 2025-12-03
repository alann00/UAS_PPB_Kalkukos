<?php
header('Content-Type: application/json');
include "config.php";

$nama = $_POST['nama_pengeluaran'] ?? '';
$jumlah = $_POST['jumlah_biaya'] ?? '';
$kategori = $_POST['kategori'] ?? '';
$tanggal = $_POST['tanggal_transaksi'] ?? '';

if ($nama == "" || $jumlah == "" || $kategori == "" || $tanggal == "") {
    echo json_encode(["status" => "error", "msg" => "Field tidak lengkap"]);
    exit;
}

$query = mysqli_query($conn, "
    INSERT INTO pengeluaran (nama_pengeluaran, jumlah_biaya, kategori, tanggal_transaksi)
    VALUES ('$nama', '$jumlah', '$kategori', '$tanggal')
");

if ($query) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "msg" => mysqli_error($conn)]);
}
?>
