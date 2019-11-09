#!/usr/bin/env bash

##
# Copyright (c) 2019 Samsung Electronics Co., Ltd. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##
# @file     pr-prebuild-coverity.sh
# @brief    This module examines C/C++ source code to find defects and security vulnerabilities
#
#  Coverity is a static code analysis tool from Synopsys. This product enables engineers and security teams
#  to quickly find and fix defects and security vulnerabilities in custom source code written in C, C++, 
#  Java, C#, JavaScript and more.
#	
#  Coverity Scan is a free static-analysis cloud-based service for the open source community. 
#  The tool analyzes over 3900 open-source projects and is integrated with GitHub and Travis CI.
#
# @see      https://scan.coverity.com/github
# @see      https://scan.coverity.com/download?tab=cxx
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @note Supported build type: meson
# @note CI administrator must install the Coverity package in the CI server as following:
#  $ firefox https://scan.coverity.com/download 
#  $ cd /opt
#  $ tar xvzf cov-analysis-linux64-2019.03.tar.gz
#  $ vi ~/.bashrc
#    # coverity path
#    export PATH=/opt/cov-analysis-linux64-2019.03/bin:$PATH
#  $ cov-build --dir cov-int <build_command>
#


## @brief A coverity web-crawler to fetch defects from scan.coverity.com
function coverity-crawl-defect {
    wget -a cov-report-defect-debug.txt -O cov-report-defect.html  https://scan.coverity.com/projects/nnsuite-nnstreamer

    # Check the frequency for build submissions to coverity scan
    # https://scan.coverity.com/faq#frequency
    # Up to 28 builds per week, with a maximum of 4 builds per day, for projects with fewer than 100K lines of code
    # Up to 21 builds per week, with a maximum of 3 builds per day, for projects with 100K to 500K lines of code
    # Up to 14 builds per week, with a maximum of 2 build per day, for projects with 500K to 1 million lines of code
    # Up to 7 builds per week, with a maximum of 1 build per day, for projects with more than 1 million lines of code
    time_limit_hour=23  # unit is hour
    stat_last_build=$(cat ./cov-report-defect.html | grep "Last build analyzed" -A 1 | tail -n 1 | cut -d'>' -f 2 | cut -d'<' -f 1)
    echo -e "[DEBUG] Last build analyzed: $stat_last_build"

    stat_last_build_quota_full=0
    time_build_status="hour"

    # check the build frequency with a day unit (e.g., Last build analyzed	3 days ago).
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

    # check the build frequency with a hour unit (e.g., Last build analyzed	2 hours ago).
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

    # Fetch the defect, outstadning, dismissed, fixed from scan.coverity.com
    # e.g.,  Defect summary,  Defect status, and Defect changes

    echo -e "Defect summary: "
    stat_last_analyzed=$(cat ./cov-report-defect.html | grep "Last Analyzed" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Last Analyzed: $stat_last_analyzed"
    stat_loc=$(cat ./cov-report-defect.html | grep "Lines of Code Analyzed" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Lines of Code Analyzed: $stat_loc"
    stat_density=$(cat ./cov-report-defect.html | grep "Defect Density" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Defect Density $stat_density"

    stat_total_defects=$(cat ./cov-report-defect.html | grep "Total defects" -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "Total defects: $stat_total_defects"

    stat_outstanding=$(cat ./cov-report-defect.html   | grep "Outstanding"   -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Outstanding: $stat_outstanding"


    stat_fixed=$(cat ./cov-report-defect.html         | grep "Fixed"         -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Fixed: $stat_fixed"

    echo -e "Defect changes since previous build: "
    stat_newly=$(cat ./cov-report-defect.html         | grep "Newly detected"         -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Newly detected: $stat_newly"
    stat_eliminated=$(cat ./cov-report-defect.html         | grep "Eliminated"         -B 1 | head -n 1 | cut -d'<' -f3 | cut -d'>' -f2 | tr -d '\n')
    echo -e "- Eliminated: $stat_eliminated"

    # TODO: we can get more additional information if we login at the 'build' webpage of scan.coverity.com.
    # https://scan.coverity.com/users/sign_in 
    if [[ $_login -eq 1 ]]; then
        wget -a cov-report-defect-build.txt -O cov-report-build.html  https://scan.coverity.com/projects/nnsuite-nnstreamer/builds/new?tab=upload
        stat_build_status=$(cat ./cov-report-build.html  | grep "Last Build Status:" )
        echo -e "[DEBUG] Build Status: $stat_build_status"
    fi
}

# @brief [MODULE] TAOS/pr-prebuild-coverity
function pr-prebuild-coverity(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-prebuild-coverity: Check defects and security issues in C/C++ source codes with coverity"
    pwd

    # Environment setting for Coverity
    # If you install the coverity package in the another folder without the below folder, you must modify the below statement.
    export PATH=/opt/cov-analysis-linux64-2019.03/bin:$PATH

    # Check if server administrator install required commands
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

    check_result="skip"

    # Display the coverity version that is installed in the CI server.
    # Note that the out-of-date version can generate an incorrect result.
    coverity --version

    # Read file names that a contributor modified (e.g., added, moved, deleted, and updated) from a last commit.
    # Then, inspect C/C++ source code files from *.patch files of the last commit.
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    for i in ${FILELIST}; do
        # Skip the obsolete folder
        if [[ ${i} =~ ^obsolete/.* ]]; then
            continue
        fi
        # Skip the external folder
        if [[ ${i} =~ ^external/.* ]]; then
            continue
        fi
        # Handle only text files in case that there are lots of files in one commit.
        echo "[DEBUG] file name is (${i})."
        if [[ `file ${i} | grep "ASCII text" | wc -l` -gt 0 ]]; then
            # in case of C/C++ source code
            case ${i} in
                # in case of C/C++ code
                *.c|*.cc|*.cpp|*.c++)
                    # Check the defects of C/C++ file with coverity. The entire procedure is as following:

                    echo -e "[DEBUG] (${i}) file is source code with the text format."

                    # Step 1/4: run coverity (cov-build) to execute a static analysis
                    # configure the compiler type and compiler command.
                    # https://community.synopsys.com/s/article/While-using-ccache-prefix-to-build-project-c-primary-source-files-are-not-captured
                    # [NOTE] You need to change the variables appropriately if your project does not use ccache, gcc, and g++.
                    # The execution result of the coverity-build command is dependend on the build style of the source code.
                    cov-configure --comptype prefix --compiler ccache
                    cov-configure --comptype gcc --compiler cc
                    cov-configure --comptype g++ --compiler c++

                    analysis_sw="cov-build"
                    analysis_rules="--dir cov-int"
                    coverity_result="coverity_defects_result"

                    # Check the build submission qutoa for this project
                    # https://scan/coverity.com/faq#frequency
                    # Activity1: get build status from https://scan.coverity.com/projects/<your-github-project-name>/builds/new.
                    # Activity2: Check the current build submission quota
                    # Activity3: Stop or run the coverity scan service with the build quota
                    coverity-crawl-defect
    
                    # Create a JSON file for display coverity badge that describes the number of the defects
                    echo -e "[DEBUG] the folder of the coveirty badge file (json): "
                    echo -e "[DEBUG] ls ../../../../badge/ "
                    ls -al ../../../../badge/
                    echo -e "{"                                 > ../../../../badge/badge_coverity.json
                    echo -e "    \"schemaVersion\": 1,"        >> ../../../../badge/badge_coverity.json
                    echo -e "    \"label\": \"coverity\","     >> ../../../../badge/badge_coverity.json
                    echo -e "    \"message\": \""$stat_total_defects "defects\"," >> ../../../../badge/badge_coverity.json
                    echo -e "    \"color\": \"brightgreen\","  >> ../../../../badge/badge_coverity.json
                    echo -e "    \"style\": \"flat\""          >> ../../../../badge/badge_coverity.json
                    echo -e "}"                                >> ../../../../badge/badge_coverity.json
        
                    if [[ $stat_last_build_quota_full -eq 1 ]]; then
                        echo -e "[DEBUG] Sorry. The build quota of the coverity scan is exceeded."
                        echo -e "[DEBUG] Stopping the coverity module."
                        # if frequenced of cov-build exceeds quota, let's stop the next tasks.
                        break;
                    fi

                    # Run 'cov-build' command for the static analysis
                    cov_build_result=0
                    if  [[ $_cov_build_type -eq "meson" ]]; then
                        build_cmd="ninja -C build-coverity"
                        rm -rf ./build-coverity/
                        echo -e "[DEBUG] Generating config files with meson command."
                        echo -e "[DEBUG] meson build-coverity "
                        meson build-coverity
                        echo -e "[DEBUG] Compiling the source files with '$build_cmd' command."
                        echo -e "[DEBUG] $analysis_sw $analysis_rules $build_cmd > ../report/coverity_build_result.txt "
                        $analysis_sw $analysis_rules $build_cmd > ../report/coverity_build_result.txt
                        cov_build_result=`cat ../report/coverity_build_result.txt | grep "The cov-build utility completed successfully" | wc -l`
                    else
                        echo -e "[DEBUG] Sorry. We currently provide the meson build type."
                        echo -e "[DEBUG] If you want to add new build type, Please contribute the build type."
                        echo -e "[DEBUG] Stopping the coverity module."
                        # If cov-build is not executed normally, let's stop the next tasks.
                        break;
                    fi
                  
                    # Step 2/4: commit the otuput to scan.coverity.com
                    # Report the execution result.
                    if  [[ $cov_build_result -eq 1 ]]; then
                        echo "[DEBUG] $analysis_sw: PASSED. current file: '${i}', result value: '$cov_build_result' ."
                        # commit the execution result of the coverity
                        _cov_version=$(date '+%Y%m%d-%H%M')
                        _cov_description="${date}-coverity"
                        _cov_file="cov_project.tgz"


                        # create a tar archive from  the results (the 'cov-int' folder).
                        tar cvzf $_cov_file cov-int

                        # Please make sure to include the '@' sign before the tarball file name.
                        echo -e "[DEBUG] curl --form token=****** --form email=$_cov_email --form file=@$_cov_file --form version="$_cov_version" --form description="$_cov_description" $_cov_site -o ../report/coverity_curl_output.txt "

                        curl --form token=$_cov_token \
                          --form email=$_cov_email \
                          --form file=@$_cov_file \
                          --form version="$_cov_version" \
                          --form description="$_cov_description" \
                          $_cov_site \
                          -o ../report/coverity_curl_output.txt
                        result=$?
                       
                        # Note that curl gets value (0) even though you use a incorrect file name.
                        if [[ $result -eq 0 ]]; then
                            echo -e "[DEBUG] Please visit https://scan.coverity.com/projects/<your-github-repository>"
                        else
                            echo -e "[DEBUG] Ooops... The return value is $result. The coverity task is failed."
                        fi
                    else
                        echo "[DEBUG] $analysis_sw: FAILED. current file: '${i}', result value: '$cov_build_result' ."

                    fi
                    # Although source files are 1+, we just run once because coverity inspects all source files.
                    break
                    ;;
                * )
                    echo "[DEBUG] The coverity does not examine (${i}) file because it is not specified source codes."
                    ;;
            esac
        fi
    done
   
    # Step 3/4: change the execution result of the coverity module according to the execution result 
    # TODO: Get additional information from https://scan.coverity.com with a webcrawler
    # 1. How can we know if coverity can be normally executed or not? with the curl_output.txt file
    # 2. How do we know the time that the coverity scan completes? with a webcrawler
    # 3. How do we check changes of defects between pre-PR and post-PR? with a webcrawler

    echo -e "[DEBUG] if (stat_total_defects: $stat_total_defects -le _cov_warning_card: $_cov_warning_card)"
    if [[ -z "$stat_total_defect" ]]; then
        check_result="skip"
    elif [[ $stat_total_defects -eq 0 ]]; then
        check_result="success"
    elif [[ $stat_total_defects -le $_cov_warning_card ]]; then
        check_result="yellowcard"
    elif [[ $stat_total_defects -gt $_cov_warning_card ]]; then
        check_result="redcard"
    else
        check_result="failure"
    fi
    # Create a summary report on defects
    msg_defects="${msg_defects}\n#### :orange_book: Coverity Scan Summary:\n"
    msg_defects="${msg_defects}|Content |Description |\n"
    msg_defects="${msg_defects}|-------------------|-------------------|\n"
    msg_defects="${msg_defects}|Last Analyzed |$stat_last_analyzed|\n"
    msg_defects="${msg_defects}|Lines of Code Analyzed |$stat_loc|\n"
    msg_defects="${msg_defects}|Defect Density |$stat_density|\n"
    msg_defects="${msg_defects}|Total defects |$stat_total_defects|\n"
    msg_defects="${msg_defects}| - Outstanding |$stat_outstanding|\n"
    msg_defects="${msg_defects}| - Newly detected |$stat_newly|\n"
    msg_defects="${msg_defects}| - Eliminated |$stat_eliminated|\n"

    # Create defect icons with the number of the defects
    msg_bugs="$msg_bugs\n#### :orange_book: Defects:\n"
    for (( i=1;i<=$stat_total_defects;i++ )) ; do
        if [[ $i -le $_cov_warning_card ]]; then
            msg_bugs="$msg_bugs :mask: "
        else
            msg_bugs="$msg_bugs :rage: "
        fi
    done

 
    echo -e "[DEBUG] check_result is ( $check_result )."
    # Step 4/4: comment the summarized report on a PR if defects exist.
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. Static code analysis tool for security - coverity."
        message="Successfully coverity has done the static analysis."
        cibot_report $TOKEN "success" "TAOS/pr-prebuild-coverity" "$message" "$_cov_prj_website" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "skip" ]]; then
        echo "[DEBUG] Skipped. Static code analysis tool for security - coverity."
        message="Skipped. This module did not inspect your PR because it does not include source code files."
        cibot_report $TOKEN "success" "TAOS/pr-prebuild-coverity" "$message" "$_cov_prj_website" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "yellowcard" ]]; then
        echo "[DEBUG] Ooops. Yellow Card: The number of defects exceeds $_cov_warning_card - coverity."
        message="Ooops. Yellow Card: The number of defects ($stat_total_defects) exceeds $_cov_warning_card. Please fix defects less than $_cov_warning_card."
        cibot_report $TOKEN "success" "TAOS/pr-prebuild-coverity" "$message" "$_cov_prj_website" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
        # Inform a PR submitter of current defects status of Coverity scan
        message=":octocat: **cibot**: $user_id, **Coverity Report**, **[YELLOWCARD]**: Ooops. The number of defects exceeds $_cov_warning_card. Please fix defects until less than $_cov_warning_card. For more details, please visit ${_cov_prj_website}.\n\n$msg_defects\n\n$msg_bugs\n\n"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    elif [[ $check_result == "redcard" ]]; then
        echo "[DEBUG] Ooops. Red Card: The number of defects exceeds $_cov_warning_card - coverity."
        message="Ooops. Red Card: The number of defects ($stat_total_defects) exceeds $_cov_warning_card. Please fix defects less than $_cov_warning_card."
        cibot_report $TOKEN "success" "TAOS/pr-prebuild-coverity" "$message" "$_cov_prj_website" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
        # Inform a PR submitter of current defects status of Coverity scan
        message=":octocat: **cibot**: $user_id, **Coverity Report**, **[REDCARD]**: Ooops.The number of defects exceeds $_cov_warning_card. Please fix defects until less than $_cov_warning_card. For more details, please visit ${_cov_prj_website}.\n\n$msg_defects\n\n$msg_bugs\n\n"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    else
        echo "[DEBUG] Failed. Static code analysis tool for security - coverity."
        message="Oooops. coverity is not completed. Please ask the CI administrator on this issue."
        cibot_report $TOKEN "failure" "TAOS/pr-prebuild-coverity" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        # Inform a PR submitter of a hint in more detail
        message=":octocat: **cibot**: $user_id, **${i}** is not inspected successfully by the coverity module."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
    

}

