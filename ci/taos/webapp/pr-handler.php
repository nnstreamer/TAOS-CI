<?php
session_start();
if(!isset($_SESSION['id'])) {
    echo "<script>window.alert('로그인이 필요합니다.');</script>";
    echo "<script>window.location='./user_login.php';</script>";
    //header('Location: ./user_login.php');
}
?>


<!DOCTYPE html>
<html lang="ko">
<head>
<meta name="viewport" content="width=device-width, user-scalable=no">
<script type="text/javascript">
  function showpopup_event_store_name() {
      window.open("popup_event_store_name.php", "_blank", "width=400, height=200, left=100, top=50");
  }
  function showpopup_event_start_time() {
      window.open("popup_event_start_time.php", "_blank", "width=400, height=200, left=100, top=50");
  }
  function showpopup_event_msg() {
      window.open("popup_event_msg.php", "_blank", "width=400, height=200, left=100, top=50");
  }
  function showpopup_password() {
      window.open("popup_password.php", "_blank", "width=400, height=200, left=100, top=50");
  }
</script>

<title>고객용:이벤트 일정 업로드</title>
</head>
<body>
<form name="uploadForm" id="uploadForm" method="post" action="event_upload_process.php" enctype="multipart/form-data" onsubmit="return formSubmit(this);">
<div>
<a href="./event_file_list.php"><img src=./images/file-list.png alt="이벤트 일정 리스트로 이동하기" title="이벤트 일정 리스트로 이동하기" border=0 width=50 height=50></img></a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<br>
<font size=5 color=black> 이벤트 일정 업로드 화면</font>
<br>
<font color=blue>설명이 필요한 경우 <img src=images/item.png border=0 height=15 width=15 />을 클릭하여 정보를 확인하세요.</font>
<br><br>
<font size=5  Color=black><img src=images/item.png onclick="showpopup_event_store_name();" onmouseover="this.style.cursor='pointer'" border=0 height=25 width=25 />상점명<font color=red>*</font> <INPUT TYPE=TEXT NAME=store STYLE="BACKGROUND-COLOR: #DDDDD0" SIZE=20 MAXLENGTH=20 READONLY VALUE="<?= $_SESSION['name'] ?>" > <br><br> </font>

<!--
<font size=5  Color=black>시작 시간 <INPUT TYPE=TEXT NAME=time STYLE="BACKGROUND-COLOR: #99ff99" SIZE=12 MAXLENGTH=12><br><br> </font>
//-->
<?php
date_default_timezone_set("Asia/Seoul");
$input_year   = date("Y");
$input_month  = date("m");
$input_day    = date("d");
$input_hour   = date("H");
$input_minute = floor(date("i")/10)*10;
// if a minute value is 0, let's modify the value with "00".
if ($input_minute ==  "0")
    $input_minute = "00";

?>
<font size=5  Color=black><img src=images/item.png onclick="showpopup_event_start_time();" onmouseover="this.style.cursor='pointer'" border=0 height=25 width=25 />시작 시간  </font>
<select name="start_year" STYLE="BACKGROUND-COLOR: #99FF99">
            <option value="<?=$input_year ?>" STYLE="BACKGROUND-COLOR: #99ff99" selected(초기 선택된 항목)><?=$input_year ?></option>
            <option value="2018" STYLE="BACKGROUND-COLOR: #99ff99">2018</option>
            <option value="2019" STYLE="BACKGROUND-COLOR: #99ff99">2019</option>
            <option value="2020" STYLE="BACKGROUND-COLOR: #99ff99">2020</option>
            <option value="2021" STYLE="BACKGROUND-COLOR: #99ff99">2021</option>
</select>년 
<select name="start_month"STYLE="BACKGROUND-COLOR: #99FF99">
            <option value="<?=$input_month ?>" STYLE="BACKGROUND-COLOR: #99ff99" selected(초기 선택된 항목)><?=$input_month ?></option>
            <option value="01" STYLE="BACKGROUND-COLOR: #99ff99">01</option>
            <option value="02" STYLE="BACKGROUND-COLOR: #99ff99">02</option>
            <option value="03" STYLE="BACKGROUND-COLOR: #99ff99">03</option>
            <option value="04" STYLE="BACKGROUND-COLOR: #99ff99">04</option>
            <option value="05" STYLE="BACKGROUND-COLOR: #99ff99">05</option>
            <option value="06" STYLE="BACKGROUND-COLOR: #99ff99">06</option>
            <option value="07" STYLE="BACKGROUND-COLOR: #99ff99">07</option>
            <option value="08" STYLE="BACKGROUND-COLOR: #99ff99">08</option>
            <option value="09" STYLE="BACKGROUND-COLOR: #99ff99">09</option>
            <option value="10" STYLE="BACKGROUND-COLOR: #99ff99">10</option>
            <option value="11" STYLE="BACKGROUND-COLOR: #99ff99">11</option>
            <option value="12" STYLE="BACKGROUND-COLOR: #99ff99">12</option>

</select>월
<select name="start_day"STYLE="BACKGROUND-COLOR: #99ff99">
            <option value="<?=$input_day ?>" STYLE="BACKGROUND-COLOR: #99ff99" selected(초기 선택된 항목)><?=$input_day ?></option>
            <option value="01" STYLE="BACKGROUND-COLOR: #99ff99">01</option>
            <option value="02" STYLE="BACKGROUND-COLOR: #99ff99">02</option>
            <option value="03" STYLE="BACKGROUND-COLOR: #99ff99">03</option>
            <option value="04" STYLE="BACKGROUND-COLOR: #99ff99">04</option>
            <option value="05" STYLE="BACKGROUND-COLOR: #99ff99">05</option>
            <option value="06" STYLE="BACKGROUND-COLOR: #99ff99">06</option>
            <option value="07" STYLE="BACKGROUND-COLOR: #99ff99">07</option>
            <option value="08" STYLE="BACKGROUND-COLOR: #99ff99">08</option>
            <option value="09" STYLE="BACKGROUND-COLOR: #99ff99">09</option>
            <option value="10" STYLE="BACKGROUND-COLOR: #99ff99">10</option>
            <option value="11" STYLE="BACKGROUND-COLOR: #99ff99">11</option>
            <option value="12" STYLE="BACKGROUND-COLOR: #99ff99">12</option>
            <option value="10" STYLE="BACKGROUND-COLOR: #99ff99">10</option>
            <option value="11" STYLE="BACKGROUND-COLOR: #99ff99">11</option>
            <option value="12" STYLE="BACKGROUND-COLOR: #99ff99">12</option>
            <option value="13" STYLE="BACKGROUND-COLOR: #99ff99">13</option>
            <option value="14" STYLE="BACKGROUND-COLOR: #99ff99">14</option>
            <option value="15" STYLE="BACKGROUND-COLOR: #99ff99">15</option>
            <option value="16" STYLE="BACKGROUND-COLOR: #99ff99">16</option>
            <option value="17" STYLE="BACKGROUND-COLOR: #99ff99">17</option>
            <option value="18" STYLE="BACKGROUND-COLOR: #99ff99">18</option>
            <option value="19" STYLE="BACKGROUND-COLOR: #99ff99">19</option>
            <option value="20" STYLE="BACKGROUND-COLOR: #99ff99">20</option>
            <option value="21" STYLE="BACKGROUND-COLOR: #99ff99">21</option>
            <option value="22" STYLE="BACKGROUND-COLOR: #99ff99">22</option>
            <option value="23" STYLE="BACKGROUND-COLOR: #99ff99">23</option>
            <option value="24" STYLE="BACKGROUND-COLOR: #99ff99">24</option>
            <option value="25" STYLE="BACKGROUND-COLOR: #99ff99">25</option>
            <option value="26" STYLE="BACKGROUND-COLOR: #99ff99">26</option>
            <option value="27" STYLE="BACKGROUND-COLOR: #99ff99">27</option>
            <option value="28" STYLE="BACKGROUND-COLOR: #99ff99">28</option>
            <option value="29" STYLE="BACKGROUND-COLOR: #99ff99">29</option>
            <option value="30" STYLE="BACKGROUND-COLOR: #99ff99">30</option>
            <option value="31" STYLE="BACKGROUND-COLOR: #99ff99">31</option>
</select>일
<select name="start_hour"STYLE="BACKGROUND-COLOR: #99ff99">
            <option value="<?=$input_hour ?>" STYLE="BACKGROUND-COLOR: #99ff99" selected(초기 선택된 항목)><?=$input_hour ?></option>
            <option value="01" STYLE="BACKGROUND-COLOR: #99ff99">01</option>
            <option value="02" STYLE="BACKGROUND-COLOR: #99ff99">02</option>
            <option value="03" STYLE="BACKGROUND-COLOR: #99ff99">03</option>
            <option value="04" STYLE="BACKGROUND-COLOR: #99ff99">04</option>
            <option value="05" STYLE="BACKGROUND-COLOR: #99ff99">05</option>
            <option value="06" STYLE="BACKGROUND-COLOR: #99ff99">06</option>
            <option value="07" STYLE="BACKGROUND-COLOR: #99ff99">07</option>
            <option value="08" STYLE="BACKGROUND-COLOR: #99ff99">08</option>
            <option value="09" STYLE="BACKGROUND-COLOR: #99ff99">09</option>
            <option value="10" STYLE="BACKGROUND-COLOR: #99ff99">10</option>
            <option value="11" STYLE="BACKGROUND-COLOR: #99ff99">11</option>
            <option value="12" STYLE="BACKGROUND-COLOR: #99ff99">12</option>
            <option value="13" STYLE="BACKGROUND-COLOR: #99ff99">13</option>
            <option value="14" STYLE="BACKGROUND-COLOR: #99ff99">14</option>
            <option value="15" STYLE="BACKGROUND-COLOR: #99ff99">15</option>
            <option value="16" STYLE="BACKGROUND-COLOR: #99ff99">16</option>
            <option value="17" STYLE="BACKGROUND-COLOR: #99ff99">17</option>
            <option value="18" STYLE="BACKGROUND-COLOR: #99ff99">18</option>
            <option value="19" STYLE="BACKGROUND-COLOR: #99ff99">19</option>
            <option value="20" STYLE="BACKGROUND-COLOR: #99ff99">20</option>
            <option value="21" STYLE="BACKGROUND-COLOR: #99ff99">21</option>
            <option value="22" STYLE="BACKGROUND-COLOR: #99ff99">22</option>
            <option value="23" STYLE="BACKGROUND-COLOR: #99ff99">23</option>
            <option value="00" STYLE="BACKGROUND-COLOR: #99ff99">00</option>
</select>시
<select name="start_minute"STYLE="BACKGROUND-COLOR: #99ff99">
            <option value="<?=$input_minute ?>" STYLE="BACKGROUND-COLOR: #99ff99" selected(초기 선택된 항목)><?=$input_minute ?></option>
            <option value="00" STYLE="BACKGROUND-COLOR: #99ff99">00</option>
            <option value="10" STYLE="BACKGROUND-COLOR: #99ff99">10</option>
            <option value="20" STYLE="BACKGROUND-COLOR: #99ff99">20</option>
            <option value="30" STYLE="BACKGROUND-COLOR: #99ff99">30</option>
            <option value="40" STYLE="BACKGROUND-COLOR: #99ff99">40</option>
            <option value="50" STYLE="BACKGROUND-COLOR: #99ff99">50</option>
</select>분


<br><br>
<font size=5  Color=black><img src=images/item.png onclick="showpopup_event_msg();" onmouseover="this.style.cursor='pointer'" border=0 height=25 width=25 />입력 내용 <INPUT TYPE=TEXT NAME=message STYLE="BACKGROUND-COLOR: #99ff99" SIZE=60 MAXLENGTH=60><br><br>

</font>
<font size=5  Color=black><img src=images/item.png onclick="showpopup_password();" onmouseover="this.style.cursor='pointer'" border=0 height=25 width=25 />비밀번호  <INPUT TYPE=TEXT NAME=password STYLE="BACKGROUND-COLOR: #DDDDD0" SIZE=30 MAXLENGTH=30 READONLY VALUE="<?= $_SESSION['password'] ?>">
</font>
<br>
<font color=blue>
(비밀번호는 로그인 암호로 자동 반영됩니다.)<br><br>
</font>
<br>
<br>
<br>
<input type="submit" value="등록하기" />
</form>

</body>
</html>
