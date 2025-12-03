<?php
header('Content-Type: application/json');
include "config.php";

// Cek apakah semua data ada
if (!isset($_POST['nama_tagihan']) || !isset($_POST['nominal']) || !isset($_POST['tanggal_jatuh_tempo'])) {
    echo json_encode(["status" => false, "message" => "Data tidak lengkap"]);
    exit;
}

$nama = $_POST['nama_tagihan'];
$nominal = $_POST['nominal'];
$tanggal = $_POST['tanggal_jatuh_tempo'];

$query = "INSERT INTO tagihan_bulanan (nama_tagihan, nominal, tanggal_jatuh_tempo, is_paid)
          VALUES ('$nama', '$nominal', '$tanggal', 0)";

if (mysqli_query($conn, $query)) {
    echo json_encode(["status" => true, "message" => "Tagihan berhasil ditambahkan"]);
} else {
    echo json_encode(["status" => false, "message" => "Gagal menambah tagihan"]);
}
?>
