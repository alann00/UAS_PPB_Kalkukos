<?php
header('Content-Type: application/json');
include "config.php";

if (!isset($_POST['id']) || !isset($_POST['is_paid'])) {
    echo json_encode(["status" => false, "message" => "Data tidak lengkap"]);
    exit;
}

$id = $_POST['id'];
$isPaid = $_POST['is_paid'];

$query = "UPDATE tagihan_bulanan SET is_paid = '$isPaid' WHERE id = '$id'";

if (mysqli_query($conn, $query)) {
    echo json_encode(["status" => true, "message" => "Status diperbarui"]);
} else {
    echo json_encode(["status" => false, "message" => "Gagal update status"]);
}
?>