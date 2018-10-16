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
 *    @file   webhook.php
 *    @brief  Github webhook handler
 *
 *    It is an event handler based on github webhook API to automatically
 *    control and maintain when issues and PRs happen.
 *
 *    License: Apache-2.0
 *    (c) 2018 Geunsik Lim <geunsik.lim@samsung.com>
 *
 *    @param None
 */

/**
 *    @mainpage   CI bot
 *    @section intro Introduction
 *    - Introduction        :  A webhook handler to process github events such as ISSUE, PR, and PUSH 
 *    @section   Program       Program Name
 *    - Program Name        :  A CI bot to support continuous integration
 *    - Program Details     :  Generate outputfile.html  after doing build, install, and unit-test
 *    @section  INOUTPUT       input/output data
 *    - INPUT               :  None
 *    - OUTPUT              :  Execution result of CI
 *    @section  CREATEINFO     Code information
 *    - initial date        :  2017/07/30
 *    - version             :  1.03
 */

/** Declare global variables */
$hookSecret="";
$rawPost="";
$json="";
$open_sesame="";
$github_dns="";


/**
 * @brief read json file
 */
function json_config(){
    global $github_dns;
    echo ("<img src=./image/webhook-flow.png border=0></img><br>\n");
    echo ("<style> table { border: 1px solid #444444; } </style>\n");
    echo ("<table bgcolor=gray><tr><td width=800></td></tr></table>\n");
    echo ("[DEBUG] PRINT: <font color=blue><b>A webhook engine is started.....</b></font> <br>\n");
    // read JSON file
    $string = file_get_contents("./config/config-webhook.json");
    $json_config = json_decode($string);

    // get website name of github from json file
    $github_dns = $json_config->github->website;

    // get id from json file
    $github_id = $json_config->github->id;
    // Note that you have to use 'print_r' instead of echo function to display a decoded object (json data).
    // Run print_r ($json_config) in case that you have to display an object class;
    printf ("[DEBUG] json config: your webhook ID: %s\n<br>", $json_config->github->id);
    $vowels = array(" ", "\\", "$");
    $secret_hidden = str_replace($vowels, "_", $json_config->github->secret);
    printf ("[DEBUG] json config: your webhook secret: %s\n<br>", substr_replace($secret_hidden,"******",3));

    // Please, add "$hookSecret" value in Secret field at https://<github-address>/.../setting/hooks/
    // Set NULL if you want to disable this security.
    global $hookSecret;
    $hookSecret = $json_config->github->secret;
}

/**
 * @brief get payload contents
 */
function get_payload_contents(){
    global $hookSecret;
    global $rawPost;
    global $json;
    // user-defined error handling function
    set_error_handler(function($severity, $message, $file, $line) {
       throw new \ErrorException($message, 0, $severity, $file, $line);
    });

    // user-defined exception handling function
    set_exception_handler(function($e) {
        header('HTTP/1.1 500 Internal Server Error');
        echo "[DEBUG] ERROR: <font color=red>Ooops. This webpage is a security zone. Do not try to do an illegal access.</font><br>\n";
        echo "[DEBUG] ERROR: This error is generated on <b>line {$e->getLine()}</b> of the <b>".basename($_SERVER['PHP_SELF'])."</b> file by exception handling facility.<br>\n";
        echo "[DEBUG] ERROR: ".htmlSpecialChars($e->getMessage())."<br>\n";
        die();
    });

    // check the secret value between cibot and github setting (e.g., Secret).
    $rawPost = NULL;
    if ($hookSecret !== NULL) {
        if (!isset($_SERVER['HTTP_X_HUB_SIGNATURE'])) {
            throw new \Exception("HTTP header 'X-Hub-Signature' is missing.");
        } elseif (!extension_loaded('hash')) {
            throw new \Exception("Missing 'hash' extension to check the secret code validity.");
        }
        list($algo, $hash) = explode('=', $_SERVER['HTTP_X_HUB_SIGNATURE'], 2) + array('', '');
        if (!in_array($algo, hash_algos(), TRUE)) {
            throw new \Exception("Hash algorithm '$algo' is not supported.");
        }
        $rawPost = file_get_contents('php://input');
        if ($hash !== hash_hmac($algo, $rawPost, $hookSecret)) {
            throw new \Exception('Hook secret does not match.');
        }
    }

    // get content type
    $ContentType = $_SERVER['CONTENT_TYPE'];
    printf ("[DEBUG] Content type: '$ContentType' \n");

    // Note that data structure of payload  depends on triggered event
    // https://developer.github.com/v3/activity/events/types/
    switch ($ContentType) {
        case 'application/json':
            $json = $rawPost ?: file_get_contents('php://input');
            break;
        case 'application/x-www-form-urlencoded':
            $json = $_POST['payload'];
            break;
        default:
            throw new \Exception("Unsupported content type: $_SERVER[HTTP_CONTENT_TYPE]");
    }
}

/**
 * @brief decode json data
 */
function decode_json_data(){
    global $payload;
    global $json;
    // Decode the payload string of json type.
    // If the second parameter is set to 'true', the JSON string will be parased to an array, not stdClass.
    // $payload = json_decode($json,true);
    $payload = json_decode($json);

    echo ("[DEBUG] json string is decoded..... \n");
    echo ("[DEBUG] action: '$payload->action'. \n");

}

/**
 * @brief create time with microseconds
 *
 * u (Microseconds) is added in PHP 5.2.2. Note that date() will always generate 000000
 * since it takes an integer parameter, whereas DateTime::format() does support microseconds
 * if DateTime was created with microseconds
 */
function date_time_us(){
    date_default_timezone_set('Asia/Seoul');
    $date=date("YmdHis").(date('u')+fmod(microtime(true), 1));
    return $date;
}

/**
 * @brief check open sesame tag
 * checker: support "@open sesame mm/dd hh:mm" facility to recall CI task in case of a system error.
 * let's enable "@open sesame" statement in PR title to support self assessment
 * For more details, refer to https://en.wikipedia.org/wiki/Open_Sesame_(phrase)
 */
function check_open_sesame(){
    global $payload;
    global $open_sesame;
      echo ("[DEBUG] #### checker: starting '@open sesame' check routine \n");
       $pr_title=$payload->{"pull_request"}->{"title"};
       $pattern="/@open sesame[^.]+\/+[^.]+\:+[^.]/i";
       if (preg_match($pattern, $pr_title, $matches)) {
        echo "[DEBUG] '@open sesame' is enabled. a matched data is '".$matches[0]."'. \n";
           $open_sesame="true";
       }
       else {
           echo "[DEBUG] '@open sesame' is disabled. a matched data is nothing. \n";
           $open_sesame="false";
       }
}

/**
 * @brief github event handling
 *
 * github event handler: execute an appropriate activity whenever a github envent type happens.
 * https://developer.github.com/enterprise/2.10/webhooks/#events
 */
function github_event_handling(){
    global $payload;
    global $open_sesame;
    global $github_dns;
    switch (strtolower($_SERVER['HTTP_X_GITHUB_EVENT'])){
        case 'issues':
            // checker: Comment some messages automatically when new issue is created.
            if ($payload->action == "opened"){
                $issue_no=$payload->issue->number;
                printf ("[DEBUG] current issue number: $issue_no \n\n");
                $result = shell_exec("./checker-issue-comment.sh $issue_no");
                printf ("[DEBUG] result:\n %s", $result);
                printf ("[DEBUG] ./checker-issue-comment.sh $issue_no \n");
            }
            break;
        case 'issue_comment':
            // NYI: reponse to PR comment?
            break;
        case 'pull_request':
            // checker: Comment some messages automatically whenever new PR happens.
            if ($payload->action == "opened"){
                printf ("\n\n");
                echo ("[DEBUG] #### checker: starting checker-pr-comment.sh .... \n");
                echo ("[DEBUG] action: '$payload->action'. \n");
                $pr_no=$payload->pull_request->number;
                printf ("[DEBUG] current PR number: $pr_no \n\n");
                $result = shell_exec("./checker-pr-comment.sh $pr_no");
                printf ("[DEBUG] result of shell script:\n %s", $result);
                printf ("[DEBUG] ./checker-pr-comment.sh $pr_no \n");
            }
            // checker: let's inspect if there are a "Signed-off-by" string in PR body
            // let's verify all commits that include signed-off statement in PR body in advance
            // Note that the "Signed-off-by" statement is automatically mirrored from a commit message when send 'git push'.
            // Todo: handle  PR that has multiple commits using "foreach $payload->head as $key => $value" statement.
            if ($payload->action == "opened" ||
            $payload->action == "edited" ||
            $payload->action == "synchronize"){
                printf ("\n\n");
                echo ("[DEBUG] #### checker: starting checker-pr-signed-off-by.sh ... \n");
                echo ("[DEBUG] action: '$payload->action'. \n");
                $pr_no=$payload->pull_request->number;
                $pr_commit=$payload->pull_request->head->sha;
                echo ("[DEBUG] sha: $pr_commit . \n");
                $pr_body=$payload->{"pull_request"}->{"body"};
                if (preg_match('/Signed-off-by/i', $pr_body)) {
                    echo "[DEBUG] Passed. $pr_commit is signed-off with 'Signed-off-by:' string.\n";
                    $sign_off_result="success";
                }
                else {
                    echo "[DEBUG] Failed. $pr_commit is not signed-off with 'Signed-off-by:' string.\n";
                $sign_off_result="failure";
                }
                printf ("[DEBUG] pr_no result: (%s)\n", $pr_no);
                printf ("[DEBUG] pr_commit result: (%s)\n", $pr_commit);
                printf ("[DEBUG] signed_off result: (%s)\n", $sign_off_result);
                $result = shell_exec("./checker-pr-signed-off-by.sh $pr_no $pr_commit $sign_off_result");
                //printf ("[DEBUG] result of shell script:\n (%s)", $result);
                printf ("[DEBUG] ./checker-pr-signed-off-by.sh $pr_no $pr_commit $sign_off_result \n");
            }

            printf ("\n\n");
            check_open_sesame();

            // Checker: checker-pr-gateway.sh
            if ($payload->action == "opened" || ($payload->action == "edited" && $open_sesame == "true")||
                $payload->action == "synchronize"){
                printf ("\n\n");
                printf ("[DEBUG] #### checker: starting ./checker-pr-gateway.sh ...)\n");
                echo ("[DEBUG] action: '$payload->action'. \n");
                $date=date_time_us();
                $commit = $payload->pull_request->head->sha;
                $full_name = $payload->pull_request->head->repo->full_name;
                $repo = "https://${github_dns}/${full_name}.git";
                $branch = $payload->pull_request->head->ref;
                $pr_no=$payload->pull_request->number;
                $delivery_id = $_SERVER['HTTP_X_GITHUB_DELIVERY'];
                printf ("[DEBUG] current PR number: $pr_no \n");
                printf ("[DEBUG] arg1) date: $date \n");
                printf ("[DEBUG] arg2) commit: $commit \n");
                printf ("[DEBUG] arg3) repo: $repo \n");
                printf ("[DEBUG] arg4) branch: $branch \n");
                printf ("[DEBUG] arg5) pr no: $pr_no \n");
                printf ("[DEBUG] arg6) X-GitHub-Delivery: $delivery_id \n");

                // Run a shell script asynchronously to avoid service timeout generated
                // due to a long execution time.
                // https://stackoverflow.com/questions/222414/asynchronous-shell-exec-in-php
                // https://stackoverflow.com/questions/2368137/asynchronous-shell-commands
                $result=0;
                $cmd="./checker-pr-gateway.sh $date $commit $repo $branch $pr_no $delivery_id > /dev/null 2>/dev/null &";
                $result=shell_exec($cmd);
                printf ("[DEBUG] checker: checker-pr-gateway.sh is done asynchronously. \n");
                printf ("[DEBUG] It means that checker-pr-gateway.sh is still running now.\n");
                printf ("[DEBUG] ./checker-pr-gateway.sh $date $commit $repo $branch $pr_no $delivery_id \n");

            }

            break;
        case 'pull_request_review':
            break;
        case 'push':
            // NYI: Pushed to master?
            // if ($payload->ref === 'refs/heads/master'){
            // Run the build script as a background process
            // ./build.sh {$url} {$payload->repository->name} > /dev/null 2>&1 &`;
            // }
            break;
        case 'create':
            // Run an appropriate script as a background process
            break;
        default:
            // header('HTTP/1.0 404 Not Found');
            echo "[DEBUG] Exception handling: cibot does not handle '$_SERVER[HTTP_X_GITHUB_EVENT]'\n";
                    echo "[DEBUG] Payload:\n";
                    echo "[DEBUG] #####################################################\n";
            print_r($payload); # For debug only. Can be found in GitHub hook log.
                    echo "[DEBUG] #####################################################\n";
            //die();
                    break;
    }
}

/**
 * @brief  Main fuction
 */
function main(){
    json_config();
    get_payload_contents();
    decode_json_data();
    github_event_handling();
}

main();

?>
