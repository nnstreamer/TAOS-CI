<html>
<head>
<title>Broken Arrow</title>
</head>
<body>
<font size=18>"Broken Arrow" Situation: </font> <br>
<br><br>
This interface is to run the "<b>Broken Arrow</b>" strategy when the system administrator <br>
can not find a recipe to solve a cirtical issue such as PR hangs due to unknown reasons.<br>

<ul> <li>
Broken Arrow refers to an accidental event that involves nuclear weapons, warheads<br>
or components which does not create the risk of nuclear war. These include unexplained<br>
nuclear detonation, non-nuclear detonation, radioactive contamination, and public hazard.
</li>
</ul>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src=./broken-arrow.png border=0></img>
<br><br>
<script>
function ConfirmCmd()
{
    var x = confirm("Are you sure you want to run Broken Arrow?");
    if (x)
        return true;
    else 
        return false;
}
</script>

<form action="broken-arrow-proceed.php" method="post">
<table border=0>
<tr>
<td><img src=./circle.png with=20 height=20>ID</td><td><input type="text" name="id"><br></td>
</tr>
<tr>
<td><img src=./circle.png with=20 height=20>Password</td><td><input type="password" name="pass"><br></td>
</tr>
<tr>
<td>
<br>
<input type="submit" onClick="return ConfirmCmd()" value="Click"></td>
<td></td>
</tr>
</form>

</body>
</html>

