<html>
<head>
<title>PR: Resource Usage (pstree)</title>
<meta http-equiv="refresh" content="6; URL=./pstree.php">
<meta name="keywords" content="automatic redirection">
</head>
<body>
<img src=monitor-icon.png border=0><font color=whiteblue> <b>PR: Resource Usage (pstree)</b></font>
<br><br>

<font color=green>
When PR does not completed in time due to a system overload, it is to show running<br>
processes as a tree. The tree is rooted at either pid or init if pid is omitted.<br>
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
$cmd = "pstree -p | aha --black --line-fix";
$output = shell_exec($cmd);
echo "$output";
echo "========================================================";
?>
</body>
</html>
