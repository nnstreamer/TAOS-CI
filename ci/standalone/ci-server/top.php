<html>
<head>
<title>PR: Resource Usage (top)</title>
<meta http-equiv="refresh" content="3; URL=./top.php">
<meta name="keywords" content="automatic redirection">
</head>
<body>
<img src=monitor-icon.png border=0><font color=whiteblue> <b>PR: Resource Usage (top)</b></font>
<br><br>

<font color=green>
When PR does not completed in time due to a system overload, it is to monitor CPU,<br>
Memory, and SWAP usage. So you can see all the processes and threads running<br>
on the system as well as viewing them as a process tree.<br>
</font>

<?php
echo "========================================================";
$output = shell_exec("COLUMNS=200 top -H -b -c -n 1 | aha --black --line-fix");
echo "$output";
echo "========================================================";
?>
</body>
</html>
