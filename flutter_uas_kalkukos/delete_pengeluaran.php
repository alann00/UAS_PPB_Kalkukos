<?php
header('Content-Type: application/json');
include "config.php";

// pastikan menerima POST id
$id = $_POST['id'] ?? null;

if (!$id) {
    echo json_encode([
        "status" => "error",
        "message" => "ID tidak ditemukan"
    ]);
    exit;
}

$query = $conn->query("DELETE FROM pengeluaran WHERE id = '$id'");

if ($query) {
    echo json_encode([
        "status" => "success",
        "message" => "Data berhasil dihapus"
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => $conn->error
    ]);
}
?>
