<?php
header('Content-Type: application/json');
include "config.php";

if (!isset($_POST['id'])) {
    echo json_encode(["status" => false, "message" => "ID tidak dikirim"]);
    exit;
}

$id = $_POST['id'];

$query = "DELETE FROM tagihan_bulanan WHERE id = '$id'";

if (mysqli_query($conn, $query)) {
    echo json_encode(["status" => true, "message" => "Tagihan berhasil dihapus"]);
} else {
    echo json_encode(["status" => false, "message" => "Gagal menghapus tagihan"]);
}
?>
