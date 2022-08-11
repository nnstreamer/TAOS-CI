#!/usr/bin/env bash
## SPDX-License-Identifier: Apache-2.0

## @file     checker-pr-gateway.sh
## @brief    A PR gateway to control two PR checkers such as prebuild and postbuild
## First of all, it clones a github repository with "git clone" command
## when a contributor submits a PR. Then, it run prebuild and postbuild module sequentially.
##
## @see      https://github.com/nnstreamer/TAOS-CI
## @author   Geunsik Lim <geunsik.lim@samsung.com>
## @param arguments are received from CI manager
##  arg1: date(Ymdhms)
##  arg2: commit number
##  arg3: repository address of PR
##  arg4: branch name
##  arg5: PR number
##  arg6: delivery id
##
## @see variables to control the directories
##  $dir_ci directory is CI folder (Absolute path)
##  $dir_worker   directory is PR worker folder
##  $dir_commit   directory is commit folder

# ------------ Initialize execution environment -------------------------------------

# Arguments
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6


# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation.
source ./config/config-environment.sh
pwd

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    echo -e "[ERROR] Oooops. We can not run $0 due to incorrect arguments."
    echo -e "[ERROR] Unexpectedly $0 Stopped."
    exit 1
fi

# Load API library
source ./common/api_collection.sh

# Check if dependent packages are installed
echo -e "[DEBUG] Checking dependent commands...\n"
check_cmd_dep tee
check_cmd_dep rm

# ----------- Calculate dir_cir, dir_worker, and dir_commit ------------------------------

# Set folder name uniquely to run CI in different folder per a PR.
cd ..
export dir_ci=`pwd`

# Check if dir_commit folder exists, then, create dir_commit folder
# Let's keep the existing result although the same target directory already exists.
cd $dir_ci
dir_worker="repo-workers/pr-checker"
export dir_worker=$dir_worker
export dir_commit=${dir_worker}/${input_pr}-${input_date}-${input_commit}

# Check if a same commit folder already exists
if [[ -d $dir_commit ]]; then
    echo -e "[DEBUG] 'mkdir' command is failed because $dir_commit directory already exists."
    echo -e "[DEBUG] So removing the existing directory..."
    rm -rf ./${dir_commit}
fi

# Create a commit folder
cd $dir_ci
mkdir -p $dir_commit
echo -e "[DEBUG] $dir_commit folder is created."

# Specify a log file name of gateway facility
logfile_gateway="${dir_ci}/${dir_commit}/pr-gateway.txt"
echo -e "[DEBUG] Starting PR gateway facility ..." | tee -a $logfile_gateway

# ------------ (De)Activate SELECTIVE_PR_AUDIT to handle PRs selectively ----------------

if [[ $SELECTIVE_PR_AUDIT -eq 1 ]]; then
    # Ideally, one GitHub repository must include one project.
    # IF the one has to include other repositoris, git package recommends
    # that they use "git submodule" commmand. Nevertheless, if they maintain
    # lots of project with just folder structure in one GitHub repository,
    # We handle a repository that consits of many projects in one repository
    # with PR_ACTIVATE_DIR in the configuration file.
    echo -e "[DEBUG] The selective PR Audit is activated as this PR modifies the $PR_ACTIVATE_DIR folder." | tee -a $logfile_gateway

    # Check if dependent packages are installed
    check_cmd_dep curl
    check_cmd_dep grep
    check_cmd_dep echo
    check_cmd_dep awk

    pr_files=$(curl -H "Authorization: token ${TOKEN}" ${GITHUB_WEBHOOK_API}/pulls/${input_pr}/files | grep "filename" | awk '{print $2}')
    detected=$(echo ${pr_files} | grep ${PR_ACTIVATE_DIR})

    # Decide CI activation finally. Continue a PR examination when there are matched files only.
    if [[ -z $detected ]]; then
        echo -e "[DEBUG] -------------------------------------------" | tee -a $logfile_gateway
        echo -e "[DEBUG] There are no matched files." | tee -a $logfile_gateway
        echo -e "[DEBUG] -------------------------------------------" | tee -a $logfile_gateway
        exit 99
    else
        echo -e "[DEBUG] -------------------------------------------" | tee -a $logfile_gateway
        echo -e "${pr_files}" | tee -a $logfile_gateway
        echo -e "[DEBUG] -------------------------------------------" | tee -a $logfile_gateway
    fi
else
    echo -e "[DEBUG] The selective PR Audit is deactivated since the SELECTIVE_PR_AUDIT is not '1'." | tee -a $logfile_gateway
fi

# --------------------------- git-clone module: clone a git repository ----------------------
echo -e "[DEBUG] Starting 'git clone' command to get a git repository...." | tee -a $logfile_gateway

# Set project repo name of contributor
PRJ_REPO_OWNER=`echo $(basename "${input_repo%.*}")`

# Check if a git repository already exists
cd $dir_commit
if [[ -d ${PRJ_REPO_OWNER} ]]; then
    echo -e "[DEBUG] ${PRJ_REPO_OWNER} already exists and is not an empty directory." | tee -a $logfile_gateway
    echo -e "[DEBUG] Removing the existing directory..." | tee -a $logfile_gateway
    rm -rf ./${PRJ_REPO_OWNER}
fi

# create 'report' folder to archive log files.
pwd
mkdir ./report
echo -e "[DEBUG] The 'report' folder is created." | tee -a $logfile_gateway

# run "git clone" command to download git source
# options of 'sudo' command:
# 1) The -H (HOME) option sets the HOME environment variable to the home directory of the target user (root by default)
# as specified in passwd. By default, sudo does not modify HOME.
# 2) The -u (user) option causes sudo to run the specified command as a user other than root. To specify a uid instead of a username, use #uid.
pwd
run_git_clone="sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo"
echo -e "[DEBUG] $run_git_clone"
$run_git_clone
if [[ $? != 0 ]]; then
    echo "[DEBUG] ERROR: 'git clone' is failed due to incorrect setting of CI server." | tee -a $logfile_gateway
    echo "[DEBUG] ERROR: git clone --reference ${REFERENCE_REPOSITORY} $input_repo" | tee -a $logfile_gateway
    echo "[DEBUG] Please check /var/www/ permission, /var/www/html/.netrc, and /var/www/html/.gbs.conf." | tee -a $logfile_gateway
    echo "[DEBUG] current id: $(id)" | tee -a $logfile_gateway
    echo "[DEBUG] current path: $(pwd)" | tee -a $logfile_gateway
    echo "[DEBUG] $run_git_clone" | tee -a $logfile_gateway

    exit 1
fi

# run "git branch" to use commits from PR branch
echo -e "[DEBUG] PRJ_REPO_OWNER is ./${PRJ_REPO_OWNER}" | tee -a $logfile_gateway
cd ./${PRJ_REPO_OWNER}
checkout_branch="git checkout -b $input_branch origin/$input_branch"
echo -e "[DEBUG] $checkout_branch" | tee -a $logfile_gateway
$checkout_branch
git branch
pwd


## @brief checker runner to run the checkers based on the dependency policy
## Run the first group, then depending on the dependency policy, run the remaining groups
## @param arguments received by the function
##  arg1: list of checkers (like prebuild, postbuild, etc)
##  arg2: list of checker's name
##  arg3: list of checker's log file
##  arg@: all remaining arguments are to be passed to the checkers (common for all the checkers)
function run_all_checkers(){
  local -n cmd_list=$1
  local -n name_list=$2
  local -n logfile_list=$3
  local checker_args=${@:4}
  declare -i status=0
  local num_checkers=${#cmd_list[@]}
  for (( i=0; i<$num_checkers; i++ )); do
    local logfile=${logfile_list[$i]}

    cd $dir_ci
    echo -e "[DEBUG] dir_commit is $dir_commit. This folder is created." | tee    $logfile
    echo -e "[DEBUG] current path: $(pwd)."                              | tee -a $logfile
    # Save a log file to debug the cheker
    echo -e "[DEBUG] ${cmd_list[$i]} $checker_args "                     | tee -a $logfile
    echo -e "[DEBUG] Starting a ${name_list[$i]} checker... "            | tee -a $logfile
    # Run checker
    # Currently, there are two checkers such as prebuild and postbuild.
    # The current modules of the prebuild group is not heavy.
    # But, if the prebuild module  needs more times to complete the modules, please consider introduce
    # to run the checkers asynchronously with the background command (e.g., command | tee -a $logfile &).
    # Note that you must modify the Out-of-PR (OOP) killer because OOP killer depends on synchronous method.
    pushd ./taos/
    ${cmd_list[$i]} $checker_args                                        | tee -a $logfile
    status+=${PIPESTATUS[0]}
    ## in case of running async, save pid and wait later
    local pid=$!
    echo -e "[DEBUG] Running... ${cmd_list[$i]} pid: ${pid} status: ${status}" | tee -a $logfile_gateway
    local pids[${i}]=$pid
    popd

    # if the dependency between groups is to be enforced and current group fails, skip remaining groups
    if [[ $dep_policy_between_groups == 1 ]]; then
      wait $pid
      if [[ $? != 0 || $status != 0 ]]; then
        break
      fi
    fi
  done

  # if checkers are running asynchronously, wait explicitly to check if every thing was successful
  for pid_ in ${pids[*]}; do
    echo -e "[DEBUG] waiting... pid: ${pid_}"                         | tee -a $logfile_gateway
    wait $pid_
    status+=$?
  done

  # this means every checker was successful
  if [[ $status == 0 ]]; then
    # Let's approve it as a reviewer if this PR passes all CI modules.
    if [[ $pr_comment_review_activity == 1 ]]; then
        # Get user ID from the input_repo string
        set -- "${input_repo}"
        IFS="\/"; declare -a Array=($*); unset IFS;
        user_id="@${Array[3]}"

        message=" $user_id, :100: All CI checkers are successfully verified. Thanks."
        cibot_review $TOKEN "APPROVE" "$message" "$input_commit" "$GITHUB_WEBHOOK_API/pulls/$input_pr/reviews"
    fi
  fi
}

# --------------------------- Create and run checkers -------------------------------------
# Create an empty list for the checkers to be run with the corresponding elements
# The order of the checkers in the list creates a dependency between them determining the order in which they will run
# 1) Checker itself to be run
# 2) Name of the checker
# 3) Log file to log the output of the checker
declare -a checker_cmd_list
declare -a checker_name_list
declare -a checker_logfile_list

# Ready a module: the prebuild group
checker_cmd_list+=("./checker-pr-prebuild-async.sh")
checker_name_list+=("prebuild")
checker_logfile_list+=("${dir_ci}/${dir_commit}/pr-prebuild-group.txt")
echo -e "[DEBUG] Added ${checker_name_list[-1]} module." | tee -a $logfile_gateway

# Ready a module: the postbuild group
checker_cmd_list+=("./checker-pr-postbuild-async.sh")
checker_name_list+=("postbuild")
checker_logfile_list+=("${dir_ci}/${dir_commit}/pr-postbuild-group.txt")
echo -e "[DEBUG] Added ${checker_name_list[-1]} module." | tee -a $logfile_gateway

# Run all the modules (both the pre-build and post group) sequentially
echo -e "[DEBUG] Running all modules" | tee -a $logfile_gateway
run_all_checkers checker_cmd_list checker_name_list checker_logfile_list $1 $2 $3 $4 $5 $6
echo -e "[DEBUG] Completed all modules" | tee -a $logfile_gateway

