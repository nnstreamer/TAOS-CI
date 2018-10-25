
# Coding Convention

ROS Application follows [Google Style Guide](https://google.github.io/styleguide/cppguide.html) for coding convention. 
A few rules might be ignored depending on modules. For the full list of ignored rules, please see the following link:

## C/C++
When you push your commits, ALWAYS run clang-format & cpplint to submit a commit with style change. If there is a change due to code style issues, make two separate commits: (Please do not include other codes' style change in the same commit)
- commit with style change only (i.e., commit clang-formatted original code - not your code change)
- commit with your code change only (i.e., contents only).

### clang-format (https://clang.llvm.org/docs/ClangFormat.html)
clang-format automatically formats your code.
Please, refer to http://releases.llvm.org/3.9.0/tools/clang/docs/ClangFormatStyleOptions.html for more details.
1. Install the latest clang-format (>= 3.8)
```bash
$ sudo apt-cache search clang-format
$ sudo apt-get install -y clang-format-XX.XX
```
2. Copy clang-format file from AuDri/ROS/catkin/style/.clang-format to your caktin workspace (catkin_ws), or copy .clang-format to root path of source codes.
3. Run clang-format with --style=File option:
```bash
$ clang-format-XX.XX -i --style=File [my_source_code_file]
or 
$ find . -name '*.h' -or -name '*.hpp' -or -name '*.cpp' | xargs clang-format-XX.XX -i -style=file $1
```

### cpplint (https://github.com/cpplint/cpplint)
cpplint is a static C++ style checker following Google's C++ style guide. cpplint for ROS modules is available at AuDri/ROS/catkin/style/cpplint.py.

1. Directly run it with:
```bash
$ python cpplint.py [file_path]
or
$ find . -name '*.h' -or -name '*.hpp' -or -name '*.cpp' | xargs python cpplint.py $1
```

## Python

### Formatter yapf (https://github.com/google/yapf)

We use yapf as a formatter for python files.
It changes the python files according to the defined style in ~/.config/yapf/style file.
We use pep 8. We use style config as below. You can use yapf with PIP.

```bash
$ sudo pip install --proxy=http://10.112.1.184:8080 yapf
$ vi ~/.config/yapf/style
[style]
based\_on\_style = pep8
indent\_width = 4
split\_before\_logical\_operator = true
$ yapf -i *.py
```

### Checker pylint (https://www.pylint.org)

Pylint is a source code, bug and quality checker for the Python programming language. It follows the style recommended by PEP 8, the Python style guide.
To check a python file with pylint:
```bash
$ sudo pip install --proxy=http://10.112.1.184:8080 pylint
$ cd AuDri
$ cp ROS/catkin/style/.pylintrc ~/
$ pylint your_file.py
Then, modify incorrect statements that are checked by pylint before submitting your PR.
```

## PHP
### PHP_Beautifier (https://github.com/clbustos/PHP_Beautifier)
This program reformat and beautify PHP 4 and PHP 5 source code files automatically. It is written in PHP 5 and has a command line tool

```bash
$ sudo apt-get install php-pear
$ sudo pear install PHP_Beautifier-0.1.15
```

