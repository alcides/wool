cmake_minimum_required(VERSION 2.6)
project(wool C)

option(USE_NUMA "Use NUMA" ON)
option(PIE_TIMES "Record Pie Times" OFF)
option(COUNT_TASKS "Count Tasks in Wool" OFF)
option(COUNT_STEALS "Count Steals and Leaps in Wool" OFF)
option(COUNT_SPLITS "Count Splits in Wool" OFF)

include(CheckIncludeFiles)

set(numa_tools "")

if(USE_NUMA)
  check_include_files(numa.h HAVE_NUMA_H)
  if(HAVE_NUMA_H)
    set (NUMA_LIB numa)
    set (numa_tools numa_tools.c numa_tools.h)
    set (NUMA_DEF "USE_NUMA=1")
  else()
    message("No NUMA library found!")
    set (NUMA_DEF "USE_NUMA=0")
  endif()
else()
  set (NUMA_DEF "USE_NUMA=0")
endif()

if(PIE_TIMES)
  set (WOOL_PIE "WOOL_PIE_TIMES=1")
else()
  set (WOOL_PIE "WOOL_PIE_TIMES=0")
endif()

if (COUNT_TASKS)
  set (WOOL_COUNT_TASKS "WOOL_COUNT_TASKS=1")
else()
  set (WOOL_COUNT_TASKS "WOOL_COUNT_TASKS=0")
endif()

if (COUNT_STEALS)
  set (WOOL_COUNT_STEALS "WOOL_COUNT_STEALS=1")
else()
  set (WOOL_COUNT_STEALS "WOOL_COUNT_STEALS=0")
endif()

if (COUNT_SPLITS)
  set (WOOL_COUNT_SPLITS "WOOL_COUNT_SPLITS=1")
else()
  set (WOOL_COUNT_SPLITS "WOOL_COUNT_SPLITS=0")
endif()

add_custom_command(OUTPUT wool.h COMMAND ./wool-gen.sh 1 DEPENDS wool-gen.sh wool.c)

set(CMAKE_C_FLAGS "-g -O3 -Wall -Wextra")

set(wool_flags "${NUMA_DEF};${WOOL_PIE};${WOOL_COUNT_TASKS};${WOOL_COUNT_STEALS};${WOOL_COUNT_SPLITS}")

add_executable(fib-wool benchmarks/fib/fib-wool.c wool.c wool.h ${numa_tools})
set_target_properties(fib-wool PROPERTIES COMPILE_FLAGS "-I.")
set_target_properties(fib-wool PROPERTIES COMPILE_DEFINITIONS "${wool_flags}")
target_link_libraries(fib-wool pthread m ${NUMA_LIB})