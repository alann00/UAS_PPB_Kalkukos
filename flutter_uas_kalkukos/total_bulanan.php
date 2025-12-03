<?php
header("Content-Type: application/json");
include "config.php";

$res = [];

// TOTAL PENGELUARAN BULAN INI
$q1 = mysqli_query($conn, "
    SELECT IFNULL(SUM(jumlah_biaya),0) AS total
    FROM pengeluaran
    WHERE MONTH(tanggal_transaksi) = MONTH(NOW())
    AND YEAR(tanggal_transaksi) = YEAR(NOW())
");
$row1 = mysqli_fetch_assoc($q1);
$res["pengeluaran_bulan_ini"] = $row1["total"];

// TOTAL TAGIHAN DIBAYAR BULAN INI
$q2 = mysqli_query($conn, "
    SELECT IFNULL(SUM(nominal),0) AS total
    FROM tagihan_bulanan
    WHERE is_paid = 1
    AND MONTH(tanggal_jatuh_tempo) = MONTH(NOW())
    AND YEAR(tanggal_jatuh_tempo) = YEAR(NOW())
");

$row2 = mysqli_fetch_assoc($q2);   // ← sudah diperbaiki
$res["tagihan_dibayar"] = $row2["total"];

// TOTAL AKHIR
$res["total_bulanan"] = 
    $res["pengeluaran_bulan_ini"] + 
    $res["tagihan_dibayar"];

echo json_encode($res);
