<?php
header('Content-Type: application/json');
include "config.php";

$query = mysqli_query($conn, "SELECT * FROM tagihan_bulanan ORDER BY id DESC");

$data = [];
while ($row = mysqli_fetch_assoc($query)) {
    $data[] = [
        "id" => (int)$row["id"],
        "nama_tagihan" => $row["nama_tagihan"],
        "nominal" => (int)$row["nominal"],
        "tanggal_jatuh_tempo" => $row["tanggal_jatuh_tempo"],
        "is_paid" => (int)$row["is_paid"]
    ];
}

echo json_encode([
    "status" => true,
    "data" => $data
]);
