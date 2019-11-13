#!/usr/bin/env bash

# @name Coverity Scan script to check defect status of the GitHub repository.
#
# This file is a simple script to use the cloud service (scan.coverity.com) of Coverity
# that is provided by Synopsys. It means that this script does not handle any exception
# situations.
#
# @author Geunsik Lim <geunsik.lim@samsung.com>
# @note
# 1. You must register your GitHub repository and install Coverity scan package
#    before executing this script.
#  https://scan.coverity.com/download
#  https://scan.coverity.com/github
# 2. You must run this script in the root folder of the GitHub repository
#

# The account informaiton of GitHub repository
# https://scan.coverity.com/projects/<your-github-prj-name>?tab=project_settings
_user_name="nnsuite"
_repo_name="nnstreamer"
_token="1234567890123456789012"
_email="taos-ci@github.io"

# The installation path of Coverity Scan
export PATH=/opt/cov-analysis-linux64-2019.03/bin:$PATH

# Set the build type
_cov_build_type="meson"

# Check frequency of build submissions that are submitted to scan.coverity.com
# https://scan.coverity.com/faq#frequency
# Up to 28 builds per week, with a maximum of 4 builds per day, for projects with fewer than 100K lines of code
# Up to 21 builds per week, with a maximum of 3 builds per day, for projects with 100K to 500K lines of code
# Up to 14 builds per week, with a maximum of 2 build per day, for projects with 500K to 1 million lines of code
# Up to 7 builds per week, with a maximum of 1 build per day, for projects with more than 1 million lines of code
time_limit_hour=2 # unit is hour

# ------------------- Do not modify the below statements ---------------------------------
# Set variables to do commit command
export TZ=Asia/Seoul
_version=$(date '+%Y%m%d-%H%M')
_description="${_version}-coverity"

# Set websites
_coverity_commit_site="https://scan.coverity.com/builds?project=${_user_name}%2F${_repo_name}"
_coverity_repo_site_logout="https://scan.coverity.com/projects/${_user_name}-${_repo_name}"
_coverity_repo_site_login="https://scan.coverity.com/projects/${_user_name}-{$_repo_name}/builds/new?tab=upload"

# Set login status
_login=0

## @brief A coverity web-crawler to fetch defects from scan.coverity.com
function coverity-crawl-defect {
    echo -e "[DEBUG] =============================================================================="
    echo -e "[Step 1/4] Doing a crawler to collect Coverity defects...."
    echo -e "[DEBUG] =============================================================================="

    # TODO: we can get more additional information if we login at https://scan.coverity.com .
    if [[ $_login -eq 1 ]]; then
        wget -a cov-report-defect-build.txt -O cov-report-defect.html  $_coverity_repo_site_login
    else
        wget -a cov-report-defect-debug.txt -O cov-report-defect.html $_coverity_repo_site_logout
    fi
    stat_build_status=$(cat ./cov-report-defect.html  | grep "Last Build Status:" )
    echo -e "Build Status: $stat_build_status"

    stat_last_build=$(cat ./cov-report-defect.html    | grep "Last build analyzed" -A 1 | tail -n 1 | cut -d'>' -f 2 | cut -d'<' -f 1)
    echo -e "Last build analyzed: $stat_last_build"
    stat_last_build_quota_full=0
    time_build_status="hour"



    # Fetch the defect, outstadning, dismissed, fixed from scan.coverity.com
    # e.g.,  Defect summary,  Defect status, and Defect changes

    echo -e "Defect summary: $stat_total_defects"
    stat_last_analyzed=$(cat ./cov-report-defect.html | grep "Last Analyzed"  -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Last Analyzed: $stat_last_analyzed"
    stat_loc=$(cat ./cov-report-defect.html           | grep "Lines of Code Analyzed" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Lines of Code Analyzed: $stat_loc"
    stat_density=$(cat ./cov-report-defect.html       | grep "Defect Density" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Defect Density $stat_density"

    stat_total_defects=$(cat ./cov-report-defect.html | grep "Total defects"  -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "Total defects: $stat_total_defects"

    stat_outstanding=$(cat ./cov-report-defect.html   | grep "Outstanding"    -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Outstanding: $stat_outstanding" 
 
    stat_dismissed=$(cat ./cov-report-defect.html     | grep "Dismissed"      -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Dismissed: $stat_dismissed"

    stat_fixed=$(cat ./cov-report-defect.html         | grep "Fixed"          -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Fixed: $stat_fixed"

    echo -e "Defect changes: "
    stat_newly=$(cat ./cov-report-defect.html         | grep "Newly detected" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Newly detected: $stat_newly"
    stat_eliminated=$(cat ./cov-report-defect.html    | grep "Eliminated"     -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Eliminated: $stat_eliminated"

    # check the build frequency with a day unit (e.g., Last build analyzed      3 days ago).
    if [[ $stat_last_build_quota_full -eq 0 ]]; then
        stat_last_build_freq=$(echo $stat_last_build | grep "day" | cut -d' ' -f 1)
        echo -e "[DEBUG] ($stat_last_build_freq) day"
        stat_last_build_freq=$((stat_last_build_freq * 24))
        echo -e "[DEBUG] ($stat_last_build_freq) hour"
        if [[ $stat_last_build_freq -gt 0 && $stat_last_build_freq -gt $time_limit_hour ]]; then
            echo -e "[DEBUG] date:Okay. Continuing the task because the last build passed $time_limit_hour hours."
            stat_last_build_quota_full=0
            time_build_status="day"
        else
            echo -e "[DEBUG] date:Ooops. Stopping the task because the last build is less than $time_limit_hour hours."
            stat_last_build_quota_full=1
        fi
    fi

    # check the build frequency with a hour unit (e.g., Last build analyzed     2 hours ago).
    if [[ $time_build_status == "hour" ]]; then
        stat_last_build_freq=$(echo $stat_last_build | grep "hour" | cut -d' ' -f 2)
        echo -e "[DEBUG] ($stat_last_build_freq) hour"
        if [[ $stat_last_build_freq -gt 0 && $stat_last_build_freq -gt $time_limit_hour ]]; then
            echo -e "[DEBUG] hour:Okay. Continuing the task because the last build passed $time_limit_hour hours."
            stat_last_build_quota_full=0
        else
            echo -e "[DEBUG] hour:Ooops. Stopping the task because the last build is less than $time_limit_hour hours."
            stat_last_build_quota_full=1
        fi
    fi

    # If we exceeds the limitation on the number of commmits, stop the program
    if [[ $stat_last_build_quota_full == 1 ]]; then
        echo -e "[DEBUG] ========================================================================"
        echo -e "[DEBUG] Sorry. We should stop the task due to the commit limitation of Coverity."
        echo -e "[DEBUG] ========================================================================"
        exit 0
    fi

}

## @brief A coverity build function to generate intermediate output from the source code
function coverity-build {
    echo -e "[DEBUG] =============================================================================="
    echo -e "[Step 2/4] Building the source code with Coverity...."
    echo -e "[DEBUG] =============================================================================="
    # Pull changes
    git pull
    
    # configure the compiler type and compiler command
    cov-configure --comptype prefix --compiler ccache
    cov-configure --comptype gcc --compiler cc  
    cov-configure --comptype g++ --compiler c+
    
    # Run 'cov-build' command for the static analysis
    if  [[ $_cov_build_type -eq "meson" ]]; then
        echo -e "[DEBUG] Generating config files with meson command."
        rm -rf build-coverity
        rm -rf cov-int 
        meson build-coverity
        cov-build --dir cov-int ninja -C build-coverity > ./coverity_build_result.txt
    else
        echo -e "[DEBUG] Sorry. We currently provide the meson build type."
        echo -e "[DEBUG] If you want to add new build type, Please contribute the build type."
        echo -e "[DEBUG] Stopping the coverity module."
        exit 0
    fi

}

## @brief A coverity commit function to submit to the intermediate output that is generated by cov-build
function coverity-commit {
    echo -e "[DEBUG] =============================================================================="
    echo -e "[Step 3/4] Committing the intermediate files of Coverity scan to scan.coverity.com ...."
    echo -e "[DEBUG] =============================================================================="
    # exception handling
    if [[ ! $1 ]]; then
        echo "Creating the tar file ..."
        _file="myproject-${_version}.tgz"
        tar cvzf ./$_file ./cov-int/
    else
        _file="$1"
    fi
    rm $_file
 
    # commit the coverity execution result
    echo -e "[DEBUG] $_email, $_file, $_version, $_description ..."
    curl --form token=$_token \
      --form email=$_email \
      --form file=@$_file \
      --form version="$_version" \
      --form description="$_description" \
      $_coverity_commit_site \
      -o coverity_curl_output.txt
    result=$?
    
    if [[ $result -eq 0 ]]; then
        echo -e "Please visit https://scan.coverity.com/projects/<your-github-repository>"
    else
        echo -e "Ooops.... The return value is $result. The some tasks are unfortunately failed."
    fi
    echo -e "[DEBUG] for debugging, you may read coverity_build_result.txt and coverity_curl_output.txt file"
}

##
#  @brief check if a command is installed
#  @param
#   arg1: package name
function check_cmd_dep() {
    echo "Checking for $1 command..."
    which "$1" 2>/dev/null || {
      echo "Please install $1."
      exit 1
    }
}

##
# @brief check if commands exist
# @param
#  None
function check_commands() {
    echo -e "[DEBUG] =============================================================================="
    echo -e "[Step 1/4] Checking reuiqred commands ..."
    echo -e "[DEBUG] =============================================================================="
    check_cmd_dep file
    check_cmd_dep grep
    check_cmd_dep cat
    check_cmd_dep wc
    check_cmd_dep git
    check_cmd_dep tar
    check_cmd_dep cov-build
    check_cmd_dep curl
    check_cmd_dep meson
    check_cmd_dep ninja
    check_cmd_dep ccache
}


## main
check_commands
coverity-crawl-defect
coverity-build
coverity-commit
