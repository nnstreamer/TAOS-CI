
# Using gcov/lcov to generate code coverage statistics 

This document describes how to write a test coverage with GCOV and LCOV. LCOV is a graphical front-end
for GCC's coverage testing tool gcov. It collects gcov data for multiple source files and creates HTML
pages containing the source code annotated with coverage information. It also adds overview pages for
easy navigation within the file structure. LCOV supports statement, function and branch coverage measurement.

* HTML based output: coverage rates are additionally indicated using bar
  graphs and specific colors.

* Support for large projects: overview pages allow quick browsing of
  coverage data by providing three levels of detail: directory view,
  file view and source code view.


# Install required packages
```bash
$ apt install lcov
```


# Write a cpp example code
```bash
$ vi menu.cpp

#include <iostream>
using namespace std;

void showChoices();
float add(float, float);
float subtract(float, float);
float multiply(float, float);
float divide(float, float);

int main()
{
           float x, y;
           int choice;
           do
           {
                       showChoices();
                       cin >> choice;
                       switch (choice)
                       {
                       case 1:
                                   cout << "Enter two numbers: ";
                                   cin >> x >> y;
                                   cout << "Sum " << add(x,y) <<endl;
                                   break;
                       case 2:
                                   cout << "Enter two numbers: ";
                                   cin >> x >> y;
                                   cout << "Difference " << subtract(x,y) <<endl;
                                   break;
                       case 3:
                                   cout << "Enter two numbers: ";
                                   cin >> x >> y;
                                   cout << "Product " << multiply(x,y) <<endl;
                                   break;
                       case 4:
                                   cout << "Enter two numbers: ";
                                   cin >> x >> y;
                                   cout << "Quotient " << divide(x,y) <<endl;
                                   break;
                       case 5:
                                   break;
                       default:
                                   cout << "Invalid input" << endl;
                       }
           }while (choice != 5);

           return 0;
}

void showChoices()
{
           cout << "MENU" << endl;
           cout << "1: Add " << endl;
           cout << "2: Subtract" << endl;
           cout << "3: Multiply " << endl;
           cout << "4: Divide " << endl;
           cout << "5: Exit " << endl;
           cout << "Enter your choice :";
}

float add(float a, float b)
{
           return a+b;
}

float subtract(float a, float b)
{
           return a-b;
}

float multiply(float a, float b)
{
           return a*b;
}

float divide(float a, float b)
{
           return a/b;
}
```

# Generate .gcno using --coverage option
The `–coverage` option here is used to compile and link code needed for coverage analysis.
```bash
$g++ -o menu.out --coverage menu.cpp
```

# Declare environment variable
Let's change the path that .gcda files are created.
Next we need to export two variables namely `GCOV_PREFIX` and `GCOV_PREFIX_STRIP`.
Set `GCOV_PREFIX` to the folder you want the output files to be in.
The `GCOV_PREFIX_STRIP` is equal to the the number of forward slashes or “/” in the path.
```bash
$export GCOV_PREFIX="/home/taos-ci/public_html/{your_repo_name}/data"
$export GCOV_PREFIX_STRIP=5
```
# Generate .gcda
You can generate .gcda file by running the example program.
```bash
$./menu.out

MENU
1: Add
2: Subtract
3: Multiply
4: Divide
5: Exit
Enter your choice :2
Enter two numbers: 3 4
Difference -1
MENU
1: Add
2: Subtract
3: Multiply
4: Divide
5: Exit
Enter your choice :5
```

# Getting HTML output
Now, you can generate the report file with html format.

* lcov options:
   * -t: sets a test name
   * -o: to specify the output file
   * -c: to capture the coverage data
   * -d: to specify the directory where the data files needs to be searched

* genhtml option:
   * -o To specify the output folder name
```bash
$mv *.gcno ./data/
$cd data
$lcov -t "Code Coverate Statistics Report" -o lcov_app.info -c -d .
$genhtml -o html lcov_app.info
```

# Run web-server with python module
Let's run a simple web-server with the "SimpleHTTPServer" module of Python.
```bash
$cd html 
$python -m "SimpleHTTPServer"         // To start a web-server with SimpleHTTPServer
$firefox  http://localhost/index.html 
$firefox  ./html/index.html           // To open the index.html directly
```

# How to read the code coverage stats
* http://ltp.sourceforge.net/coverage/lcov/output/index.html

The `red` lines are the ones not executed or uncovered region.
The `blue` lines are the ones covered. Also you can look at the Line data section
for the number of times the lines have been executed. 

# Reference
* http://gcc.gnu.org/onlinedocs/gcc/Gcov.html
* http://ltp.sourceforge.net/coverage/lcov.php

Understood
