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
# @file  monitor.php
# @brief Monitoring PRs that possess hardware resources
# @param None
# @dependency: procps
#

#-------------------- Configuration --------------------------------------------------------
$TITLE="State Transition Monitor for PR";
$PATTERN_REQ       ="[^]] bash ./checker-pr-gateway.sh";
$PATTERN_RUN_TIZEN ="[^]]/usr/bin/python /usr/bin/gbs build";
$PATTERN_RUN_UBUNTU="[^]]/bin/bash /usr/bin/pdebuild";
$STRING_NUM_TIZEN  =5;
$STRING_NUM_UBUNTU =5;

# debugging: 1 (enabling), 0 (disabling)
$DEBUG=0;

#-------------------- Do not modify from here  ---------------------------------------------

## @brief generate HTML head tag
function display_msg($data){
    global $DEBUG;
    if ($DEBUG == 1){
        echo $data;
    }
}

## @brief generate HTML head tag
function generate_title(){
    global $TITLE;
    echo "<html>\n";
    echo "<head>\n";
    echo "<title>${TITLE}</title>\n";
    echo "<meta http-equiv=\"refresh\" content=\"3\" />\n";
    echo "</head>\n";
    echo "<body>\n";
    echo "<table width=1024 border=0><tr><td>\n";
    echo "<b><center><h2><u>${TITLE}</u></h2></center></b>\n";
    echo "<center><font size=2 color=gray>".date('jS-F-Y h:i:s A')."</font></center>\n";
    echo "<br><br> ";
}

## @brief display all PR numbers
function generate_requested_pr(){
    global $PATTERN_REQ;
    global $STRING_NUM_TIZEN;
    echo "<hr>\n";
    echo "<img src=monitor-icon.png border=0> <b>Assigned Queue: Submitted PRs</b> <br>\n";
    $output = shell_exec("ps -ef | grep \"$PATTERN_REQ\"");
    echo "<font size=2 color=blue>\n";
    if (str_word_count($output) >= $STRING_NUM_TIZEN){
        $output = str_replace("\n","<br><br>",$output);
        echo nl2br($output);
    }
    else{
        echo "<br>\n";
        echo "<center><img src=sleep.png border=0 width=100 height=100></center>\n";
    }
    echo "</font>\n";
    echo "<br><br>\n";
}

## @brief display only running PR numbers for Tizen/gbs build
function generate_running_pr_tizen(){
    global $PATTERN_RUN_TIZEN;
    global $STRING_NUM_TIZEN;
    echo "<hr>\n";
    echo "<img src=monitor-icon.png border=0> <b>Run Queue: Building Tizen PRs</b> <br>\n";
    $output = shell_exec("ps -ef | grep \"$PATTERN_RUN_TIZEN\"");
    echo "<font size=2 color=red>\n";
    if (str_word_count($output) >= $STRING_NUM_TIZEN){
        $output = str_replace("\n","<br><br>",$output);
        echo nl2br($output);
    }
    else{
        echo "<br>\n";
        echo "<center><img src=sleep.png border=0 width=100 height=100></center>\n";
    }
    echo "</font>\n";
    echo "<br><br>\n";
}

## @brief display only running PR numbers for Ubuntu/pdebuild
#  @todo have to make wrapper script (e.g., pdebuild.sh --pr xxx --commit xxx ...) to run
#        pdebuild command in order that we display a helpful message including PR number,
#        commit number, and so on.
function generate_running_pr_ubuntu(){
    global $PATTERN_RUN_UBUNTU;
    global $STRING_NUM_UBUNTU;
    echo "<hr>\n";
    echo "<img src=monitor-icon.png border=0> <b>Run Queue: Building Ubuntu PRs</b> <br>\n";
    $output = shell_exec("ps -ef | grep \"$PATTERN_RUN_UBUNTU\"");
    display_msg ("[DEBUG]   (".str_word_count($output)." >= $STRING_NUM_UBUNTU)<br>");
    echo "<font size=2 color=red>\n";
    if (str_word_count($output) >= $STRING_NUM_UBUNTU){
        $output = str_replace("\n","<br><br>",$output);
        echo nl2br($output);
    }
    else{
        echo "<br>\n";
        echo "<center><img src=sleep.png border=0 width=100 height=100></center>\n";
    }
    echo "</font>\n";
    echo "<br><br>\n";
}


## @brief generate HTML head tag
function generate_foot(){
    echo "<br><br>\n";
    echo "</td></tr></table>\n";
    echo "<font size=2>\n";
    echo "End of Line\n";
    echo "</font>\n";
    echo "<html>\n";
}

# @brief main function
generate_title();
generate_requested_pr();
generate_running_pr_tizen();
generate_running_pr_ubuntu();
generate_foot();
?>
