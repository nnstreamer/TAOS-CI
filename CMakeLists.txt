CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(taos-ci)

# Specify an installation path of TAOS-CI
IF(TAOS_CI_INSTALL_DIR)
ELSE(TAOS_CI_INSTALL_DIR)
    SET(TAOS_CI_INSTALL_DIR "/var/www/html/TAOS-CI")
ENDIF(TAOS_CI_INSTALL_DIR)

# Use GLOB_RECURSE to read all files in ./ci/ folder.
FILE(GLOB_RECURSE TAOS_CI_FILES ${PROJECT_SOURCE_DIR}/ci/*)

FUNCTION(print_list)
  FOREACH(msg ${ARGV})
    MESSAGE("${msg}")
  ENDFOREACH()
ENDFUNCTION()  
print_list(${TAOS_CI_FILES})

# Install script files for automated pull request test and webhook controller
INSTALL(DIRECTORY
       ${PROJECT_SOURCE_DIR}/ci
       DESTINATION ${TAOS_CI_INSTALL_DIR}
       USE_SOURCE_PERMISSIONS
       PATTERN "*.md" EXCLUDE
       )
