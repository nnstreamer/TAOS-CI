# How to add unit test for an AuDri application component

## Example

- [Unit Test Case for Config](https://github.sec.samsung.net/RS7-STAR/AuDri/commit/9913b8dab5578b81a7d5ffeb97d6b62e5589cf28)


## Preface

Mandatory

- A unit test case MUST be testing a unit and **independent** from other units.
  - A unit test MUST NOT depend on other external libraries or services (e.g., other ROS modules) except for the libraries required by the build.
  - A unit test MUST be able to be **executed during the build** without starting/launching any other executables.
  - A unit test MUST be testing the **corresponding unit only**.


Recommendations

- Apply unit tests to **major classes**
- Extend the target class and apply unit-testing methods to the extended class.
  - [Example](../ROS/autodrive/unittest/unittest_Config.cpp)
- Use gtest infrastructure
- In the module, separate the unit-test code subdirectory (e.g., autodrive)


## Configure ROS/component/CMakeLists.txt

[Example](../ROS/autodrive/CMakeLists.txt)

```
#############
## Testing ##
#############
find_package(rostest)
if(CATKIN_ENABLE_TESTING)
  # Unit Test during Build (make run_tests)
  catkin_add_gtest(autodrive_unittest_catkinConfig unittest/unittest_Config.cpp)
  target_link_libraries(autodrive_unittest_catkinConfig
    ${GTEST_LIBRARIES}
    ${catkin_LIBRARIES}
    ${PROJECT_NAME}
  )
endif()

# Unit Test Installation for Later Usage (for unit test suite: algo_application-unittest.rpm)
add_executable(autodrive_unittest_Config unittest/unittest_Config.cpp)
target_link_libraries(autodrive_unittest_Config
  ${GTEST_LIBRARIES}
  ${catkin_LIBRARIES}
  ${PROJECT_NAME}
)
install(TARGETS autodrive_unittest_Config
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}/gtest
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}/gtest
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}/gtest
)
```

## Configure packaging/audri.spec

Step 1. In ```%build``` section, replace
```
%cond_build name
```
with
```
%cond_build name runtest
```
Step 2. In ```%files name``` section, add
```
%exclude %{__ros_install_path}/lib/*/gtest/*
```

## Then what?

- If any other developer submits a code that breaks your module, he/she won't be able to pass the CI system so you can sleep well without worries.
- If you refactor your code, you can ensure that the correctness (the behavior) is kept equivalent.
