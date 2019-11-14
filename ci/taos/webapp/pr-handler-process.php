<!DOCTYPE html>
<html lang="ko">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width, user-scalable=no">
<title>PR Processor</title>
</head>
<body>
<?php

// Author: Geunsik Lim
// Title: A processor to handle a request of PRs
//

include('webapp_config.php');

// change last character to 0.
// For /example, convert 201805051635 to 201805051630
date_default_timezone_set("Asia/Seoul");


// This line is used for just debugging.
//$t=time();
//$curr_time = date("YmdHi",$t);
//$curr_time = substr_replace($curr_time, "", -1)."0";

$store_name = $_POST['store'];
$event_msg = $_POST['message']; 
$time_start_year = $_POST['start_year'];
$time_start_month = $_POST['start_month'];
$time_start_day = $_POST['start_day'];
$time_start_hour = $_POST['start_hour'];
$time_start_minute = $_POST['start_minute'];
$event_password = $_POST['password'];

if(empty($event_msg)) {
    echo "<script>window.alert('입력내용을 작성하여 주세요.');</script>";
    echo "<script>window.location='./event_upload.php';</script>";
}
else {
// get ip address of user
function get_client_ip()
{
     $ipaddress = '';
     if (getenv('HTTP_CLIENT_IP'))
         $ipaddress = getenv('HTTP_CLIENT_IP');
     else if(getenv('HTTP_X_FORWARDED_FOR'))
         $ipaddress = getenv('HTTP_X_FORWARDED_FOR');
     else if(getenv('HTTP_X_FORWARDED'))
         $ipaddress = getenv('HTTP_X_FORWARDED');
     else if(getenv('HTTP_FORWARDED_FOR'))
         $ipaddress = getenv('HTTP_FORWARDED_FOR');
     else if(getenv('HTTP_FORWARDED'))
         $ipaddress = getenv('HTTP_FORWARDED');
     else if(getenv('REMOTE_ADDR'))
         $ipaddress = getenv('REMOTE_ADDR');
     else
         $ipaddress = 'UNKNOWN';

     return $ipaddress;
}

$ipaddress = get_client_ip();
// echo ("[DEBUG] IP address: $ipaddress<br>");

$event_time= $time_start_year."년".$time_start_month."월".$time_start_day."일".$time_start_hour."시".$time_start_minute."분";

// ----------------------calculate the number of event data

// connect to mysql database
$db_conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
mysqli_query($db_conn, "SET NAMES utf8");
$count = 0; 
// https://dev.mysql.com/doc/refman/8.0/en/pattern-matching.html
// Pattern Matching: Use the LIKE or NOT LIKE comparison operators 
$query = "SELECT file_id, event_date, reg_time, store_name, password, event_msg FROM $table_name_event WHERE event_date LIKE '".$event_time."%' ORDER BY reg_time DESC";
$stmt = mysqli_prepare($db_conn, $query);
$exec = mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
while($row = mysqli_fetch_assoc($result)) {
    $count= $count+1;
} 
mysqli_free_result($result); 
mysqli_stmt_close($stmt);
mysqli_close($db_conn);
//echo "current time: $time , event data count: $count . <br>";
//die("just test.");


// ------------------------- upload event file to mysql database and event folder
$db_conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
mysqli_query($db_conn, "SET NAMES utf8");
$file_id = md5(uniqid(rand(), true));        
$query = "INSERT INTO $table_name_event (file_id, event_date, reg_time, store_name, password, event_msg, ip_address) VALUES(?,?,now(),'$store_name','$event_password', '$event_msg', '$ipaddress')";

$stmt = mysqli_prepare($db_conn, $query);
$bind = mysqli_stmt_bind_param($stmt, "ss", $file_id, $event_time);
$exec = mysqli_stmt_execute($stmt);
     
// disconnect mysql database connection. 
mysqli_stmt_close($stmt);
      
echo "<br>";
echo "<h3><font color=red>축하합니다.</font> 이벤트 일정을 성공적으로 업로드 하였습니다.</h3>";
echo "<a href='./event_file_list.php'>이벤트 일정 목록</a>";
}
mysqli_close($db_conn);
?>
</body>
</html>
