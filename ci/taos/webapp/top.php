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

/**
 * Copyright (c) 2018 Samsung Electronics Co., Ltd. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

echo "========================================================";
$output = shell_exec("COLUMNS=200 top -H -b -c -n 1 | aha --black --line-fix");
echo "$output";
echo "========================================================";
?>
</body>
</html>
