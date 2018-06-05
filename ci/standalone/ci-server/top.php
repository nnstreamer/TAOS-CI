<html>
<head>
<title>Monitoring resource usage of PR</title>
<meta http-equiv="refresh" content="3; URL=./top.php">
<meta name="keywords" content="automatic redirection">
</head>
<body>
<h3><b> <font color=red>Process webviewer to monitor resource usage of PRs</font></b><br>
</h3>

It  is  similar  to  top. So you can see all the processes & threads  running<br>
on the system as well as viewing them as a process tree.<br>

<?php
echo "<br>";
echo "==================================================";
$output = shell_exec("COLUMNS=200 top -H -b -c -n 1 | aha --black --line-fix");
echo "$output";
echo "==================================================";
?>
</body>
</html>
