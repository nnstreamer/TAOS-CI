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


##
# @file   pr-handler.php
# @author Geunsik Lim <geunsik.lim@samsung.com>
# @brief  A handler to control the status of the PRs manually
# @param  None
#

?>
 
<html>
<head>
<title>PR Handler:Report and Comment</title>
</head>
<body>
<font size=6>PR Report Handler: </font> <br>
<br>

<form action="pr-handler-proceed.php" method="post">
<table border=0>
<tr>
<td><img src=./circle.png with=20 height=20>ID</td><td><input type="text" name="id"><br></td>
</tr>
<tr>
<td><img src=./circle.png with=20 height=20>Password</td><td><input type="password" name="pass"><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>CI module name</td><td><input type="text" size=40 name="cimodule" value="${BOT_NAME/}/pr-postbuild-build-tizen-aarch64"><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>commit number</td><td><input type="text" size=40 name="commit" value="1f6ec74036ea816cc15659a311ac82532b0dcdd3"><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>Comment</td><td><textarea rows=6 cols=60  name="message" value="">[TEST] The current status is chaged by a web-based PR handler.</textarea><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>Status</td><td>
<select name="status" >
  <option value="success">success</option>
  <option value="failure">failure</option>
</select>
<br></td>
</tr>
<tr>
<td>
<br>
<input type="submit" onClick="return ConfirmCmd()" value="Click"></td>
<td></td>
</tr>
</form>
</table
<br>
<br>
<hr>
<font size=6>PR Comment Handler: </font> <br>
<br>

<form action="pr-handler-proceed.php" method="post">
<table border=0>
<tr>
<td><img src=./circle.png with=20 height=20>ID</td><td><input type="text" name="id"><br></td>
</tr>
<tr>
<td><img src=./circle.png with=20 height=20>Password</td><td><input type="password" name="pass"><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>PR number</td><td><input type="text" size=10 name="pr" value="1866"><br></td>
</tr>
<tr>
<td><img src=./circle.png width=20 height=20>Comment</td><td><textarea rows=6 cols=60  name="message" value="">[TEST] This comment is just test message.</textarea><br></td>
</tr>
<tr>
<td>
<br>
<input type="submit" onClick="return ConfirmCmd()" value="Click"></td>
<td></td>
</tr>
</table>
</form>
</body>
</html>


