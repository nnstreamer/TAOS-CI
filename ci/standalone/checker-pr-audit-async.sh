#!/usr/bin/env bash

##
# @file checker-pr-audit-async.sh
# @brief It executes a build test whenever a PR is submitted.
# @dependency: gbs, tee, curl, grep, wc, cat, sed, awk
# @param arguments are received by ci bot
#  arg1: date(YmdHisu)
#  arg2: commit number
#  arg3: repository address of PR
#  arg4: branch name
#  arg5: PR number
#  arg6: delivery id
#
# @see directory variables
#  $dir_ci directory for webhooks
#  $dir_worker   directory for PR workers
#  $dir_commit   directory for commits
#
# @modules:
# 1. [MODULE] CI/pr-audit-build           Check if 'gbs build' can be successfully passed.
# 2. [MODULE] plugins-good                Plugin group that follow Apache license with good quality"
# 3. [MODULE] plugins-ugly                Plugin group that does not have evaluation and aging test enough"

# --------------------------- Pre-setting module ----------------------------------------------------------------------
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6

# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation from cibot.php
source ./config/config-environment.sh

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# check if dependent packages are installed
source ./common/inspect_dependency.sh
check_package gbs
check_package tee
check_package curl
check_package grep
check_package wc
check_package cat
check_package sed
check_package awk
echo "[DEBUG] Checked dependency packages.\n"

# get user ID from the input_repo string
set -- "${input_repo}"
IFS="\/"; declare -a Array=($*); unset IFS;
user_id="@${Array[3]}"

# Set folder name uniquely to run CI in different folder per a PR.
dir_worker="repo-workers/pr-audit"

# Set project repo name
PROJECT_REPO=`echo ${input_repo##*/} | cut -d '.' -f1`

cd ..
export dir_ci=`pwd`

# create dir_work folder
if [[ ! -d $dir_worker ]]; then
    mkdir -p $dir_worker
fi
cd $dir_worker
export dir_worker=$dir_worker

# check if dir_commit folder exists, then, create dir_commit folder
# let's keep the existing result although the same target directory already exists.
cd $dir_ci
export dir_commit=${dir_worker}/${input_date}-${input_pr}-${input_commit}

# kill PIDs that were previously invoked by checker-pr-audit.sh with the same PR number.
echo "[DEBUG] Starting killing activity to kill previously invoed checker-pr-audit.sh with the smae PR number.\n"
ps aux | grep "^www-data.*bash \./checker-pr-audit.sh" | while read line
do
    victim_pr=`echo $line  | awk '{print $17}'`
    victim_date=`echo $line  | awk '{print $13}'`
    # Info: pid1 is checker-pr-audit.sh, pid2 is checker-pr-audit-async.sh, and pid3 is "gbs build" command.
    victim_pid1=`ps -ef | grep bash | grep checker-pr-audit.sh       | grep $input_pr | grep $victim_date | awk '{print $2}'`
    victim_pid2=`ps -ef | grep bash | grep checker-pr-audit-async.sh | grep $input_pr | grep $victim_date | awk '{print $2}'`
    victim_pid3=`ps -ef | grep python | grep gbs | grep "_pr_number $input_pr" | grep $victim_date | awk '{print $2}'`

    # The process killer allows to kill only task(s) in case that there are running lots of tasks with same PR number.
    if [[ ("$victim_pr" -eq "$input_pr") && (1 -eq "$(echo "$victim_date < $input_date" | bc)") ]]; then
        echo "[DEBUG] victim_pr=$victim_pr, input_pr=$input_pr, victim_date=$victim_date, input_date=$input_date "
        echo "[DEBUG] killing PR $victim_pr (pid <$victim_pid1> <$victim_pid2> <$victim_pid3>)."
        kill $victim_pid1
        kill $victim_pid2
        kill $victim_pid3
        sleep 1
        # Handle a possibility that someone updates a single PR multiple times within 1 second.
        echo "[DEBUG] removing the ./${dir_worker}/${victim_date}-${victim_pr}-* folder"
        rm -rf ./${dir_worker}/${victim_date}-${victim_pr}-*
    fi
done

# --------------------------- CI Trigger (queued) ----------------------------------------------------------------------
# inform all developers of their activity whenever developers resubmit their PR after applying comments of reviews
/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data "{\"body\":\":dart: **cibot**: $user_id has updated the pull request.\"}" \
${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

# create new context name to monitor progress status of a checker
/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data "{\"state\":\"pending\",\"context\":\"(INFO)CI/pr-audit-all\",\"description\":\"Triggered but queued. There are other build jobs and we need to wait.. The commit number is $input_commit.\",\"target_url\":\"${CISERVER}${PROJECT}/ci/${dir_commit}/\"}" \
${GITHUB_WEBHOOK_API}/statuses/$input_commit

/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data "{\"state\":\"pending\",\"context\":\"CI/pr-audit-build\",\"description\":\"Triggered but queued. There are other build jobs and we need to wait.. The commit number is $input_commit.\",\"target_url\":\"${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/\"}" \
${GITHUB_WEBHOOK_API}/statuses/$input_commit

/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data "{\"state\":\"pending\",\"context\":\"CI/pr-audit-resource\",\"description\":\"Triggered but queued. There are other build jobs and we need to wait.. The commit number is $input_commit.\",\"target_url\":\"${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/\"}" \
${GITHUB_WEBHOOK_API}/statuses/$input_commit

# --------------------------- git-clone module: clone git repository -------------------------------------------------
echo "[DEBUG] Starting pr-audit....\n"

# check if existing folder already exists
if [[ -d $dir_commit ]]; then
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
else
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory does not exists."
fi

# check if github project folder already exists
pwd
cd $dir_commit
if [[ -d ${PROJECT_REPO} ]]; then
    echo "[DEBUG] WARN: ${PROJECT_REPO} already exists and is not an empty directory."
    echo "[DEBUG] WARN: So removing the existing directory..."
    rm -rf ./${PROJECT_REPO}
fi

# create 'report' folder to archive log files.
mkdir ./report

# run "git clone" command to download git source
# options of 'sudo' command: 
# 1) The -H (HOME) option sets the HOME environment variable to the home directory of the target user (root by default)
# as specified in passwd. By default, sudo does not modify HOME.
# 2) The -u (user) option causes sudo to run the specified command as a user other than root. To specify a uid instead of a username, use #uid.
pwd
sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo
if [[ $? != 0 ]]; then
    echo "[DEBUG] ERROR: 'git clone' command is failed because of incorrect setting of CI server."
    echo "[DEBUG] Please check /var/www/ permission, /var/www/html/.netrc, and /var/www/html/.gbs.conf."
    echo "[DEBUG] current id: $(id)"
    echo "[DEBUG] current path: $(pwd)"
    echo "[DEBUG] $ sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo"
    exit 1
fi

# run "git branch" to use commits from PR branch
cd ./${PROJECT_REPO}
git checkout -b $input_branch origin/$input_branch
git branch

# --------------------------- Jenkins module: start -----------------------------------------------------

echo "[MODULE] Exception Handling: Let's skip CI-Build/UnitTest in case of no buildable files. "

# Check if PR-build can be skipped.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
SKIP=true
for file in $FILELIST
do
    if [[ "$file" =~ ($SKIP_CI_PATHS)$ ]]; then
        echo "[DEBUG] $file may be skipped."
    else
        echo "[DEBUG] $file cannot be skipped."
        SKIP=false
        break
    fi
done

# Do not run "gbs build" command in order to skip unnecessary examination if there are no buildable files.
if [ "$SKIP" = true ]; then
    echo "[DEBUG] Let's skip the 'gbs build' procedure because there is not source code. All files may be skipped."
    echo "[DEBUG] So, we stop remained all tasks at this time."
    echo "[DEBUG] 'exit 0' command will be executed right now."
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"success","context":"CI/pr-audit-build","description":"Skipped gbs build procedure. No buildable files found. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"success","context":"CI/pr-audit-resource","description":"Skipped gbs build procedure. No buildable files found. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"success","context":"(INFO)CI/pr-audit-all","description":"Skipped gbs build procedure. Successfully all audit modules are passed. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # Let's inform developers of CI test result to go to a review process as a final step before merging a PR
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":octocat: **cibot**: :+1: **(INFO)CI/pr-audit-all**: All audit modules are passed (gbs build procedure is skipped) - it is ready to review! :shipit: Note that CI bot has two sub-bots such as CI/pr-audit-all and CI/pr-format-all.\"}" \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

    # Stop to don't execute remaind tasks
    exit 0
fi

# declare default variables
check_result="success"
global_check_result="success"

if [[ -d $REPOCACHE ]]; then
    echo "[DEBUG] repocache, $REPOCACHE already exists. Good"
    # TODO: periodically delete the contents of REPOCACHE. (e.g., every Sunday?)
else
    echo "[DEBUG] repocache, $REPOCACHE does not exists. Create one"
    # Delete if it's a file.
    rm -f $REPOCACHE
    mkdir -p $REPOCACHE
fi
echo "[DEBUG] Link to the RPM repo cache to accelerate GBS start up"
mkdir -p ./GBS-ROOT/local/
pushd ./GBS-ROOT/local
ln -s $REPOCACHE cache
popd

# Let's accommodate upto 8 gbs tasks (one is "grep" process) to maintain a available system resource of the build server.
# Job queue: Fairness or FCFS is not guaranteed.
# $RANDOM is an internal bash function (not a constant) - http://tldp.org/LDP/abs/html/randomvar.html
# To enhance a job queue, refer to http://hackthology.com/a-job-queue-in-bash.html
JOBS_PR=8
while [ `ps aux | grep "sudo.*gbs build" | wc -l` -gt $JOBS_PR ]
do
    WAITTIME=$(( ( RANDOM % 20 ) + 20 ))
    sleep $WAITTIME
done

# --------------------------- CI Trigger (GBS starts) ----------------------------------------------------------------------

echo "[DEBUG] Starting CI trigger to run 'gbs build' command actually."
/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data '{"state":"pending","context":"CI/pr-audit-build","description":"Triggered and started. The commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'"}' \
${GITHUB_WEBHOOK_API}/statuses/$input_commit

echo "[DEBUG] Make sure commit all changes before running this checker."
pwd

echo "1. [MODULE] CI/pr-audit-build: Check if 'gbs build' can be successfully passed."

# DEBUG_CONSOLE is created in order that developers can do debugging easily in console after adding new CI facility.
# Note that ../report/build_log_${input_pr}_output.txt includes both stdout(1) and stderr(2) in case of DEBUG_CONSOLE=1.
# DEBUG_CONSOLE=0 : run "gbs build" command without generating debugging information.
# DEBUG_CONSOLE=1 : run "gbs build" command with generation of debugging contents.
# DEBUG_CONSOLE=99: skip "gbs build" procedures to do debugging of another CI function.

DEBUG_CONSOLE=0
if [[ $DEBUG_CONSOLE == 99 ]]; then
    echo  -e "DEBUG_CONSOLE = 99"
    echo  -e "Skipping 'gbs build' procedure temporarily to inspect other CI facilities."
elif [[ $DEBUG_CONSOLE == 1 ]]; then
    echo  -e "DEBUG_CONSOLE = 1"
    sudo -Hu www-data gbs build \
    -A x86_64 \
    --clean \
    --define "_smp_mflags -j${CPU_NUM}" \
    --define "_pr_context pr-audit" \
    --define "_pr_number ${input_pr}" \
    --define "__ros_verify_enable 1" \
    --define "_pr_start_time ${input_date}" \
    --define "_skip_debug_rpm 1" \
    --buildroot ./GBS-ROOT/  | tee ../report/build_log_${input_pr}_output.txt
else
    echo  -e "DEBUG_CONSOLE = 0"
    sudo -Hu www-data gbs build \
    -A x86_64 \
    --clean \
    --define "_smp_mflags -j${CPU_NUM}" \
    --define "_pr_context pr-audit" \
    --define "_pr_number ${input_pr}" \
    --define "__ros_verify_enable 1" \
    --define "_pr_start_time ${input_date}" \
    --define "_skip_debug_rpm 1" \
    --buildroot ./GBS-ROOT/ 2> ../report/build_log_${input_pr}_error.txt 1> ../report/build_log_${input_pr}_output.txt
fi

result=$?
echo  -e "[DEBUG] The return value of gbs build command is $result."
if [[ $result -ne 0 ]]; then
        echo "[DEBUG][FAILED] Oooops!!!!!! build checker is failed. Return value is ($result). You may refer to the execution results of 'gbs build'."
        check_result="failure"
        global_check_result="failure"
else
        echo "[DEBUG][PASSED] Successfully build checker is passed. Return value is ($result)."
        check_result="success"
fi

if [[ $check_result == "success" ]]; then
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"success","context":"CI/pr-audit-build","description":"Successfully a build checker is passed. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"failure","context":"CI/pr-audit-build","description":"Oooops. A build checker is failed. Resubmit the PR after fixing correctly. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # comment a hint on failed PR to author.
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"body":":octocat: **cibot**: '$user_id', A builder checker could not be completed because one of the checkers is not completed. In order to find out a reason, please go to '${CISERVER}${PROJECT}/ci/${dir_commit}/${PROJECT_REPO}/'."}' \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi


##################################################################################################################
echo "12. [MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo "13. [MODULE] plugins-ugly: Plugin group that does not have evaluation and aging test enough"
echo "Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/standalone/config/enable-plugins-audit.sh


##################################################################################################################

# save webhook information for debugging
echo ""
echo "[DEBUG] Start time       : ${input_date}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Commit number    : ${input_commit}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Repository       : ${input_repo}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Branch name      : ${input_branch}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] PR number        : ${input_pr}"          >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] X-GitHub-Delivery: ${input_delivery_id}" >> ../report/build_log_${input_pr}_output.txt

# optimize size of log file (e.g., from 20MB to 1MB)
# remove unnecessary contents that are created by resource checker
__log_size_filter="/]]$\|for.*req_build.*in\|for.*}'\|']'$\|found=\|basename\|search_res\|local.*'target=/ d"
sed "${__log_size_filter}" ../report/build_log_${input_pr}_output.txt > ../report/build_log_${input_pr}_output_tmp.txt
rm -f  ../report/build_log_${input_pr}_output.txt
mv ../report/build_log_${input_pr}_output_tmp.txt ../report/build_log_${input_pr}_output.txt
ls -al

# inform developers of the warning message in case that the log file exceeds 10MB.
echo "Check if the log file size exceeds 10MB."

FILESIZE=$(stat -c%s "../report/build_log_${input_pr}_output.txt")
if  [[ $FILESIZE -le 10*1024*1024 ]]; then
    echo "[DEBUG] Passed. The file size of build_log_${input_pr}_output.txt is $FILESIZE bytes."
    check_result="success"
else
    echo "[DEBUG] Failed. The file size of build_log_${input_pr}_output.txt is $FILESIZE bytes."
    check_result="failure"
    break
fi

# Add thousands separator in a number
FILESIZE_NUM=`echo $FILESIZE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
if [[ $check_result == "success" ]]; then
    # inform PR submitter of a normal execution result
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":sunny: **cibot**: $user_id, Good job. the log file does not exceed 10MB. The file size of build_log_${input_pr}_output.txt is **$FILESIZE_NUM** bytes.\"}" \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
else
    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":fire: **cibot**: $user_id, Oooops. The log file exceeds 10MB due to incorrect commit(s). The file size of build_log_${input_pr}_output.txt is **$FILESIZE_NUM** bytes. Please resubmit after updating your PR to reduce the file size of build_log_${input_pr}_output.txt.\"}" \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi

# --------------------------- Report module: submit the global check result to github.sec.samsung.net --------------
# report if all modules are successfully completed or not.
echo "send a total report with global_check_result variable. global_check_result is ${global_check_result}. "

if [[ $global_check_result == "success" ]]; then
    # The global check is succeeded.
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"success","context":"(INFO)CI/pr-audit-all","description":"Successfully all audit modules are passed. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # Let's inform developers of CI test result to go to a review process as a final step before merging a PR
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":octocat: **cibot**: :+1: **(INFO)CI/pr-audit-all**: All audit modules are passed - it is ready to review! :shipit:. Note that CI bot has two sub-bots such as CI/pr-audit-all and CI/pr-format-all.\"}" \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

elif [[ $global_check_result == "failure" ]]; then
    # The global check is failed.
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"failure","context":"(INFO)CI/pr-audit-all","description":"Oooops. One of the audits is failed. Resubmit the PR after fixing correctly. Commit number is '$input_commit'","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    # The global check is failed due to CI error.
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"state":"error","context":"(INFO)CI/pr-audit-all","description":"CI Error. There is a bug in CI script. Please contact the CI administrator.","target_url":"'${CISERVER}${PROJECT}/ci/${dir_commit}/'"}' \
    ${GITHUB_WEBHOOK_API}/statuses/$input_commit
    echo -e "[DEBUG] It seems that this script has a bug. Please check value of \$global_check_result."
fi

# --------------------------- Cleaner: remove ./GBS-ROOT/ folder to keep available storage space --------
# let's do not keep the ./GBS-ROOT/ folder because it needs a storage space more than 9GB on average.
sleep 5
echo "Removing ./GBS-ROOT/ folder."
sudo rm -rf ./GBS-ROOT/
if [[ $? -ne 0 ]]; then
        echo "[DEBUG][FAILED] Oooops!!!!!! ./GBS-ROOT folder is not removed."
else
        echo "[DEBUG][PASSED] Successfully ./GBS-ROOT folder is removed."
fi
pwd
