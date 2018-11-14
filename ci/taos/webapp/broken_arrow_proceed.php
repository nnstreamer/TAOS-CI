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
 *    @file   broken_arrow_proceed.php
 *    @brief  A runner to do "broken arrow" command.
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
$id = $_POST['id'];
$password = $_POST['pass'];

// Read a JSON file.
$string = file_get_contents("../config/config-webhook.json");
$json_config = json_decode($string);

// Get id and passowrd from json file. The prefix 'ba' means "Broken Arrow".
$ba_id = $json_config->broken_arrow->id;
$ba_password = $json_config->broken_arrow->pass;
$ba_ipaddress = $json_config->broken_arrow->ip;

// Security: Check if a IP address of a system administrator is equal to an allowed IP address.
$ipaddress = get_client_ip();
if ( $ba_ipaddress != "" && $ba_ipaddress != $ipaddress )
   die ("Unable to do the broken arrow. Specify IP address in the configuration file.")

// Check if id and password are correctly typed.
if ($id == "" || $password == "")
   die ("Unable to do the broken arrow. Please type a ID and Password.")

// Run the "BROKEN ARROW" command.
if ( $id == $ba_id && $password == $ba_password) {
    // Security: Do not type a password of a system account directly.
    $cmd = "sudo shutdown -r now";
    $output = array();
    try{
        // Keep both exec() and system() to handle different versions of PHP
        echo shell_exec($cmd);
        exec($cmd, $output);
        system($cmd, $output);
    }
    catch(Exception $e){
        echo "Caught exception: ",$e->getMessage(),"\nUnable to reboot the system....\n";
    }
    foreach ($output as $line) {
        print "$line<br>";
    }
}
else {
    echo ("Oooops. ID and password is incorrect. Please check it.");
}
?>
