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


/**
 * @file   monitor.php
 * @author Geunsik Lim <geunsik.lim@samsung.com>
 * @param  None
 *
 */


/**
 * @brief Get a client IP address
 *
 * Get IP address that a system administrator uses.
 */
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

// Get a input date from HTML FORM tag.
$id               = $_POST['id'];
$password         = $_POST['pass'];
$input_module     = $_POST['cimodule'];
$input_msg_comment= ":octocat:".$_POST['message'];
$input_msg_report = ":octocat:".$_POST['message'];
$input_status     = $_POST['status'];
$number_commit    = $_POST['commit'];
$number_pr        = $_POST['pr'];

function display_input(){
    echo ("id: $id <br>");
    echo ("password: $password <br>");
    echo ("input_module: $input_module <br>");
    echo ("input_msg_comment: $input_msg_comment <br>");
    echo ("input_msg_report: $input_msg_report <br>");
    echo ("input_status: $input_status <br>");
    echo ("commit number: $number_commit <br>");
    echo ("pr number: $number_pr <br>");
}

// Read a JSON file.
$string = file_get_contents("../config/config-webhook.json");
$json_config = json_decode($string);

// Get id and passowrd from json file. The prefix 'ba' means "Broken Arrow".
$ba_id = $json_config->broken_arrow->id;
$ba_password = $json_config->broken_arrow->pass;
$ba_ipaddress = $json_config->broken_arrow->ip;

// Security: Check if a IP address of a system administrator is equal to an allowed IP address.
$ipaddress = get_client_ip();
if ( $ba_ipaddress != "" && $ba_ipaddress != $ipaddress ) {
   echo ("Unable to do the PR handler.<br>Specify IP address in the configuration file.");
   exit(1);
}

// Check if id and password are correctly typed.
if ($id == "" || $password == "") {
    echo ("<br>
        Sorry, We can not do your request.<br>Please type a ID and Password. <br>
        <br>
        <button onclick=\"goBack()\">Go Back</button>
        <script>
         function goBack() {
         window.history.back();
        }
        </script>");
    exit(1);
}

if ( $id == $ba_id && $password == $ba_password) {
    echo ("ID and Pasword is correct.<br>");
    ?>
        <script>
          var ba_message="[NOTICE] The CI system changes the status of the specified CI module on the PR.";
          ba_message+="the comment will be displayed on the PR.";
          window.alert(ba_message);
        </script>
    <?php
    // Run the the PR comment handler. The number of argument is 2.
    if ( $input_msg_comment && $number_pr ) {
        echo ("Running the PR comment handler ...<br>");
        $cmd = "./pr-handler-runner.sh \"$input_msg_comment\" \"$number_pr\"";
        $output = array();
        try{
            flush();
            echo ("Updating the PR status.<br>");
            echo ("shell_exec(\"$cmd\")<br>");
            exec($cmd, $output);
            //system($cmd, $output);
        }
        catch(Exception $e){
            echo "Caught exception: ",$e->getMessage(),"\nUnable to change the status of the PR....\n";
        }
        //DEBUG
        //foreach ($output as $line) {
        //    print "[DEBUG] $line<br>";
        //}
     }

    // Run the the PR report handler. The number of arguments is 4.
    else if ( $input_status && $input_module && $input_msg_report && $number_commit ) {
        echo ("Running the PR comment handler ...<br>");
        $cmd = "./pr-handler-runner.sh \"$input_status\" \"$input_module\"  \"$input_msg_report\" \"$number_commit\"";
        $output = array();
        try{
            flush();
            echo ("Updating the PR status.<br>");
            echo ("shell_exec(\"$cmd\")<br>");
            exec($cmd, $output);
            //system($cmd, $output);
        }
        catch(Exception $e){
            echo "Caught exception: ",$e->getMessage(),"\nUnable to change the status of the PR....\n";
        }
        //DEBUG
        //foreach ($output as $line) {
        //    print "[DEBUG] $line<br>";
        //}
    }
    else {
    echo ("Oooops. Your input data do not satisfied with the requirement of the handlders.<br>");
    exit(1);
    }
  
    echo ("<br>
        <b>It's okay, The PR handler completed your request.</b><br>
        <br>
        <button onclick=\"goBack()\">Go Back</button>
        <script>
         function goBack() {
         window.history.back();
        }
        </script>");

}
else {
    echo ("Oooops. ID and password is incorrect.<br>");
    echo ("Please check it.<br>");
}


?>
