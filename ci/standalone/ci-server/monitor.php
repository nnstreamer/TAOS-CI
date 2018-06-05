<?php
##
# @file  monitor.php
# @brief Monitoring PRs that possess hardware resources
# @param None
# @dependency: procps
#

#-------------------- Configuration --------------------------------------------------------
$TITLE="Build Status Monitor of PRs";
$PATTERN_REQ="[^]] bash ./checker-pr-audit.sh";
$PATTERN_RUN="[^]]/usr/bin/python /usr/bin/gbs build";
$STRING_NUM=5;

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
global $STRING_NUM;
echo "<hr>\n";
echo "<img src=monitor-icon.png border=0> <b>PR list: Requested PRs</b> <br>\n";
$output = shell_exec("ps -ef | grep \"$PATTERN_REQ\"");
echo "<font size=2 color=blue>\n";
if (str_word_count($output) >= $STRING_NUM){
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

## @brief display only running PR numbers
function generate_running_pr(){
global $PATTERN_RUN;
global $STRING_NUM;
echo "<hr>\n";
echo "<img src=monitor-icon.png border=0> <b>PR list: Building PRs</b> <br>\n";
$output = shell_exec("ps -ef | grep \"$PATTERN_RUN\"");
echo "<font size=2 color=red>\n";
if (str_word_count($output) >= $STRING_NUM){
    $output = str_replace("\n","<br><br>",$output);
    echo nl2br($output);
}
else{
    echo "<br>\n";
    echo "<center><img src=sleep.png border=0 width=100 height=100></center>\n";
}
echo "</font>\n";
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
generate_running_pr();
?>
