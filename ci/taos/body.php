<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>CI</title>
</head>
<body>

<br>
<h1><b> &nbsp;&nbsp;&nbsp;&nbsp;Standalone Continuous Integration Server</b></h1>

<br>
<b>
<font color=blue>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<?php 
// Note that the github repository has to be located in /var/www/html/ folder.
$str = $_SERVER['SCRIPT_FILENAME'] ;
$chars = preg_split('/\//', $str, -1);
print_r($chars[4]);
?>
</font>
</b>
<br>
<br>
It is designed and implemented with a light-weight approach to support a desktop computer based servers<br>
that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific<br>
CI facilities, It will be easily <b>customizable</b> for your github repository because it just requires<br>
Apache and PHP package.<br>
<br>
Continuous Integration (CI) is to prevent regressions and bugs due to incorrect PRs as follows.<br>
PRs causing regressions will not be automatically merged.<br>
<br>
<li>Test automation (both build and run)</li>
<li>Preventing Performance regression</li>
<li>Finding bugs at a proper time</li>
<br>
<br>
<br>
<img src=./image/ci02.png border=0 width=550 height=200></img>
<br>
<br>
<hr>
</body>
</html>

