# How to create unit tests

- Examples
  - ROS/autodrive
    - [CMakeLists.txt](../ROS/autodrive/CMakeLists.txt)
    - [unittest sources](../ROS/autodrive/unittest/) : Covers most code
  - ROS/DataLogging/autodrive\_logger
    - [CMakeLists.txt](../ROS/DataLogging/autodrive_logger/CMakeLists.txt)
    - [unittest sources](../ROS/DataLogging/autodrive_logger/unittest/) : Template
  - ROS/Planning/decision\_make
    - [CMakeLists.txt](../ROS/Planning/decision_make/CMakeLists.txt)
    - [unittest sources](../ROS/Planning/decision_make/unittest/) : Template
  - ROS/Evaluation/ld\_evaluation
    - [CMakeLists.txt](../ROS/Evaluation/ld_evaluation/CMakeLists.txt)
    - [unittest sources](../ROS/Evaluation/ld_evaluation/unittest/) : Template

- Guide
  - Create unittest directory in the ROS module directory
  - Write unittest\_NAMEYOUWANT.cpp.
    - I recommend to write test classes inherting test-target classes.
    - Use Gtest framework (refer to the examples)
    - Try to cover all public methods
    - Try to cover major branches (if/switch/...)
  - Modify CMakeLists.txt to build the unittest (refer to the examples)
  - Modify [audri.spec](../packaging/audri.spec) to activate unit test during GBS build
    - Add ```runtests``` option to ```%cond_build MODULENAME```. Refer to the example modules
  - Then, any unit test failure will cause GBS build error; thus failing per-PR CI.

# Don't DO's

- Do not depend on any external binaries or services; i.e., ROS!
  - Create "stub" objects or methods to cover up such dependencies.
- Do not depend on other classes (classes out of the module)

# How to review unit test coverage

- [Audri Unit Test Statistics](http://aaci.mooo.com/AuDri/)
  - Updated every 15 min
  - Analyze PMB accepted commits only ([Tizen PMB](http://10.113.136.67/index.code))
- Unit Test Coverage Objectives
  - 2018.10: 60%
  - 2018.8: 40%
  - 2018.6: 10%
