
Doxygen: Generate documentation from source code
=================================================

Doxygen is the de facto regular tool for generating documentation from annotated C++ sources, however, it additionally supports different well-known programming languages akin to C, objective-C, C#, Hypertext Preprocessor, Java, Python, IDL (Corba, Microsoft, and UNO/OpenOffice flavors), Fortran, VHDL and Tcl. 

# Install doxygen & graphviz
* If you want to run [Doxygen](http://www.stack.nl/~dimitri/doxygen/) to
  produce documentation from your code comments, then in addition do the following:
  * Install [Doxygen](http://www.stack.nl/~dimitri/doxygen/) using the
    instructions on its web site. For reference, The LLVM web site is using Doxygen 1.7.6.1
    however the 1.8 series added support for Markdown formatting. We would like
    to use Markdown in our comments ASAP, so use the latest version of Doxygen.
    ```
    $ sudo apt-get install doxygen
    ```
  * Install [graphviz](http://graphviz.org/) using instructions on their
    site. The current version no longer modifies your path, so you should
    manually modify your path so that it includes "dot".
    ```
    $ sudo apt-get install graphviz
    ```

# How to generate documentation from source code
* If you want to automatically generate documentation from source code in Linux by using doxygen, proceed as follows:

    ```
    # for src app
    $ cd ./gst
    $ doxygen ../Doxyfile.prj

    # launch with the browser to view the results
    $ chromium-browser ./html/index.html
    ```

# How to comment
### Comments for Files

Each file needs to begin with the `@file` command stating the name of the file. This should be followed by a brief description of the file using the `@brief` command. If necessary, you can follow this with a more detailed description. Next you should put your name and andrew id, along with your partners name and andrew id, using the `@author` tag. This needs to be followed with a bugs section with a list of known bugs using the `@bug` command. If there are no known bugs, explicitly state that using the `@bug` command.

### Comments for Functions and Data Structures

Before each function, data structure, and macro you should put a comment block giving at least a brief description using the `@brief` command. A brief description will suffice for your data structures but for your macros and functions you will need to use a few more commands. After your description, you should use the `@param` command to describe all of the parameters to your function. These descriptions should be followed by a description of the return value using the `@return` command. Note: When we say "each" function, that is not a strong statement. You can leave out simple helper functions, like a max() macro, so you do not waste time.


### Interesting doxygen Tags & Syntax
```bash
@note: 'lhc' stands for "Large Hadron Collider" in the function/method below
@todo: Implement a delta-time loop class to replace this
@tofix:asap: Accumulator doesn't have enough precision; change type to double, and deal with the cascading effects throughout the code
@asap: Everyone, update your IDEs to newest version to avoid bug-X
@issue: I'm missing an import but I don't know which...I get 'Exception (...)'
@done: I've sent a copy of the missing lib to Bob, and explained him how to use it. Issue removed
@bug: Indicates something where a situation on the input or flow of the program leads to outright breaking of the program
```

# Case study

### Case study: C/C++
- https://www.stack.nl/~dimitri/doxygen/manual/docblocks.html#cppblock

You have to use comments starting with ** and then the special command.

* C/C++ file doxygen entries:
```bash
/**
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

/**
 * @file   taos_struct.c
 * @author Gildong Hong <gildong.hong@your.email.com>
 * @date   1/18/2018
 * @brief  A taos driver.
 *
 * These empty function definitions are provided
 * so that stdio will build without complaining.
 * You will need to fill these functions in. This
 * is the implementation of the TAOS device driver.
 * Important details about its implementation
 * should go in these comments.
 *
 * @bug     No know bugs.
 * @todo    Make it do something.
 */
int main(void){
   taos_base_initialize();
   taos_frame_run();
   return 0;
}
```

* C/C++ function doxygen entries:
```bash
/**
 * @brief	Initialize ring buffer
 * @param	RingBuff	: Pointer to ring buffer to initialize
 * @param	buffer		: Pointer to buffer to associate with RingBuff
 * @param	itemSize	: Size of each buffer item size
 * @param	count		: Size of ring buffer
 * @note	Memory pointed by a buffer must have correct alignment of
 * 			a itemSize, and a count must be a power of 2 and must at
 * 			least be 2 or greater.
 * @return	Nothing
 */
int RingBuffer_Init(RINGBUFF_T *RingBuff, void *buffer, int itemSize, int count);
```

* C/C++ struct/class doxygen entries:
```bash
/**
 * @def		RB_VHEAD(rb)
 * volatile typecasted head index
 */
#define RB_VHEAD(rb)              (*(volatile uint32_t *) &(rb)->head)

/**
 * @brief ring buffer structure
 */
typedef struct {
    void *memBuf; /**<A void * pointing to memory of size bufSize.*/
    size_t filePos; /**<Current position inside the file.*/
    size_t bufPos; /**<Curent position inside the buffer.*/
    size_t bufSize; /**<The size of the buffer.*/
    size_t bufLen; /**<The actual size of the buffer used.*/
    enum bigWigFile_type_enum type; /**<The connection type*/
    int isCompressed; /**<1 if the file is compressed, otherwise 0*/
    char *fname; /**<Only needed for remote connections. The original URL/filename requested.*/
} ring_buffer_t;

/**
 * @brief ring cache structure
 */
class ring_cache
{
  public:

    /**
     * An enum type. 
     * The documentation block cannot be put after the enum! 
     */
    enum EnumType
    {
      int EVal1,     /**< enum value 1 */
      int EVal2      /**< enum value 2 */
    };

    /**
     * a member function.
     */
    void member();
    
  protected:
    int value;       /**< an integer value */
};
```

### Case study: Python
- https://www.stack.nl/~dimitri/doxygen/manual/docblocks.html#pythonblocks

You have to use comments starting with ## and then the special command.
```bash
$ vi ./taos.py

##
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

## @package    taos
# @brief   A taos driver.
#
# These empty function definitions are provided
# so that stdio will build without complaining.
# You will need to fill these functions in. This
# is the implementation of the TAOS device driver.
# Important details about its implementation
# should go in these comments.
#
# @date    1 Dec 2017
# @param   [in] repeat number of times to do nothing
# @retval  TRUE Successfully did nothing.
# @retval  FALSE Oops, did something.
# @bug     No know bugs.
# @todo    Make it do something.
#
# Example Usage:
# @code
#   example_core(3); // Do nothing 3 times.
# @endcode
#

## @brief The constructor.
#  @param self The object pointer.
def __init__(self):
    self.__value = 0

## @brief Stores a value.
#  @param value The value to be stored.
def setValue(self, value):
    self.__value = value

## @brief Gets stored value.
#  @return The stored value.
    def getValue(self):
    return self.__value
```

### Case study: bash

You have to use comments starting with ## and then the special command.
Then, add @file and @brief tag to the top of each script file as follows.
```bash
$ vi pr-worker.sh

##
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

## @file pr-worker.sh
#  @brief function for Continuous Integration (CI)
function work_core(){
    . . . . . .
}
function work_gen(){
    . . . . . .
}
work_core
work_gen

```

Please, refer to http://www.stack.nl/~dimitri/doxygen/manual/commands.html for more details.

# How to generate the index page in HTML
If the Doxygen tag @mainpage is placed in a comment block, the block is used to
customize the index page (in HTML) or the first chapter (in $@mbox{@LaTeX}$).
The title argument is optional and replaces the default title that doxygen
normally generates. If you do not want any title you can specify notitle
as the argument of @mainpage.

Below is a simple example of a mainpage you can create yourself.

```bash
/**
 *  @mainpage   AutoDrive
 *  @section intro Introduction
 *  - Introduction      :   Application repository for autonomous solution
 *  @section   Program  Program Name
 *  - Program Name      :   AutoDrive
 *  - Program Details   :   This includes a number of internal modules which
 *  are sensing & perception, planning & control, global map generation, logging & HMI.
 *  This repository consists of TAOS-based applications as following:
 *  1) creates perception information form sensor inputs,
 *  2) handles map & routing information,
 *  3) controls the vehicle,
 *  4) and provides developers with debugging tools.
 *  @section  INOUTPUT    Input/output data
 *  - INPUT             :   None
 *  - OUTPUT            :   None
 *  @section  CREATEINFO    Code information
 *  - Initial date      :   2017/06/14
 *  - Version           :   0.1
 */
```
# How to generate script code
Refer to https://github.com/Anvil/bash-doxygen
Doxygen does not support bash script files by default.
Edit below lines in a Doxyfile.ci to generate *.sh files.

```bash
$ vi ./Doxyfile.ci
# Set your shell script file names pattern as Doxygen inputs
FILE_PATTERNS = *.sh *.php *.taos
ITAOST_FILTER = "sed -e 's|##|//!|'"
FILTER_SOURCE_FILES = YES
# Edit the Doxyfile to map shell files to C parser
EXTENSION_MAPPING = sh=C
```

# References
  * Getting started: http://www.stack.nl/~dimitri/doxygen/manual/starting.html
  * Case study (Linux kernel): https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/kernel/sched/core.c?h=v4.13-rc1#n4454

