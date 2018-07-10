#!/usr/bin/env python
#
# @Written by Sangjung Woo on Jan-09-2018 (to support auto login)
# @Modified by Seweon Oh on Jul-08-2018 (to support email notification with mailx)
# @Modified by Geunsik Lim on Jul-10-2018 (to support no_proxy setting)
# @title Auto re-login script
#
# @description
# We have always to login at least 3 times per a month to avoid
# deletion of the ID according to announcemnet of knoxportal.sec.at.samsung.com
#
# @Two conditions:
# 1. Log-in everyday
# 2. Change password every month, then replace new password with original password.
#
# @Pre-requisites:
# sudo apt-get install python-requests
# sudo apt-get install python-certifi

import requests
import sys
import os

ID = "git.bot.sec"
PASSWD = "npu*****"

login_url = "https://www.samsung.net/portal/login/login.do"
main_url = "http://kr1.samsung.net/portal/desktop/main.do"

# https://docs.python.org/3/library/os.html#process-parameters
# Note that you have to run environment manually instead of ("bash  -c 'source /etc/environment'").
# Do not write proxy setting statement inside a function.
os.environ['http_proxy'] = "http://10.112.1.184:8080/"
os.environ['https_proxy'] = "https://10.112.1.184:8080/"
os.environ['no_proxy'] = "localhost,127.0.0.1,165.213.149.200,10.113.136.32,10.113.136.201,github.sec.samsung.net,www.samsung.net,kr1.samsung.net"

def try_login(user_id, user_passwd):
    login_info = {
        "USERID": user_id,
        "USERPASSWORD": user_passwd,
        "LANG": "ko_KR.EUC-KR"
    }
    session = requests.session()
    ret = None
    try:
        ret = session.post(login_url, data=login_info)
        ret.raise_for_status()

        ret = session.get(main_url)
        ret.raise_for_status()
    except Exception as ex:
        print(ex)
        return 1

    return 0 if ret.text.find(user_id) > 0 else 1
    
    
# send e-mail if a partitions is almost full.
def email_on_failure():
    # email information
    email_cmd="mailx"
    email_subject="\"[aaci] Oooops. git.bot.sec failed auto-login.\""
    
    # email_recipient="geunsik.lim@samsung.com"    
    mail_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoong.moon@samsung.com sangjung.woo@samsung.com \
    wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
    sewon.oh@samsung.com kibeom.lee@samsung.com byoungo.kim@samsung.com "

    email_message="\n \
    Hi,\n\n \
    Ooops. git.bot.sec ID can not log-in at http://www.samsung.net.\n\n \
    Please check password of the git.bot.sec ID.\n \
    Note that CI bot of github.sec.samsung.net can not be executed if the password of the ID is broken.\n\n \
    If you want to see the evaluation result in more detail,\n \
    please visit http://aaci.mooo.com:8080/.\n\n \
    from aaci.mooo.com"


    cmd="echo '" + email_message + "' | " + email_cmd + " -v -s " + email_subject + " " + email_recipient
    os.system(cmd)    



if __name__ == "__main__":
    ret = try_login(ID, PASSWD)

    print("[Jenkins] git.bot.sec login test")
    if ret == 0:
        print("  Success!!")    
    else:
        print("  Failed!!")
        email_on_failure()
    sys.exit(ret)
