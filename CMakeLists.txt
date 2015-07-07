cmake_minimum_required(VERSION 2.6)
project(wool C)

option(USE_NUMA "Use NUMA" ON)
option(PIE_TIMES "Record Pie Times" OFF)
option(COUNT_TASKS "Count Tasks in Wool" OFF)
option(COUNT_STEALS "Count Steals and Leaps in Wool" OFF)
option(COUNT_SPLITS "Count Splits in Wool" OFF)

include(CheckIncludeFiles)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

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

add_definitions("-DCUTOFF_MECHANISM=\"${CUTOFF_MECHANISM}\"")

add_custom_command(OUTPUT wool.h COMMAND ./wool-gen.sh 32 > wool.h DEPENDS wool-gen.sh wool.c)

set(CMAKE_C_FLAGS "-g -O3 -Wall -Wno-unused -Wno-unused-parameter")

set(wool_flags "${NUMA_DEF};${WOOL_PIE};${WOOL_COUNT_TASKS};${WOOL_COUNT_STEALS};${WOOL_COUNT_SPLITS}")


macro (add_properties target)
	set_target_properties(${target} PROPERTIES COMPILE_FLAGS "-I.")
	set_target_properties(${target} PROPERTIES COMPILE_DEFINITIONS "${wool_flags}")
	target_link_libraries(${target} pthread m ${NUMA_LIB})
endmacro (add_properties)


macro (add_bots_properties target)
	set_target_properties(${target} PROPERTIES COMPILE_DEFINITIONS "${wool_flags}")
	target_link_libraries(${target} pthread m ${NUMA_LIB})
	set_target_properties(${target} PROPERTIES LINK_FLAGS "-fopenmp")
endmacro (add_bots_properties)


add_executable(fib-wool benchmarks/fib/fib-wool.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(fib-wool)

add_executable(cholesky benchmarks/cholesky/cholesky_r_opt.c wool-main.c wool.c wool.h getoptions.c getoptions.h ${numa_tools})
add_properties(cholesky)

add_executable(mm1 benchmarks/matmul/mm1.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(mm1)

add_executable(mm7 benchmarks/matmul/mm7.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(mm7)

add_executable(multisort benchmarks/multisort/multisort.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(multisort)

add_executable(nqueens benchmarks/nqueens/nqueens.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(nqueens)

add_executable(ssf benchmarks/ssf/ssf_r.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(ssf)


add_executable(stress benchmarks/stress/stress.c benchmarks/stress/loop.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(stress)


add_executable(skew benchmarks/stress/skew.c benchmarks/stress/loop.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(skew)

add_executable(uts benchmarks/uts/uts.c benchmarks/uts/uts_wool.c benchmarks/uts/rng/rng.h
benchmarks/uts/rng/brg_sha1.c wool-main.c wool.c wool.h ${numa_tools})
add_properties(uts)


# ========== BOTS ===========

FILE(GLOB BotsCommon benchmarks/bots/common/*.c)
include_directories(benchmarks/bots/common/)

add_executable(bots_fib benchmarks/bots/fib/fib.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_fib PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/fib/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_fib)

add_executable(bots_fft benchmarks/bots/fft/fft.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_fft PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/fft/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_fft)

add_executable(bots_alignment benchmarks/bots/alignment/alignment_single/alignment.c benchmarks/bots/alignment/alignment_single/sequence.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_alignment PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/alignment/alignment_single/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_alignment)

add_executable(bots_floorplan benchmarks/bots/floorplan/floorplan.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_floorplan PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/floorplan/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_floorplan)

add_executable(bots_health benchmarks/bots/health/health.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_health PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/health/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_health)

add_executable(bots_nqueens benchmarks/bots/nqueens/nqueens.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_nqueens PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/nqueens/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_nqueens)

add_executable(bots_sort benchmarks/bots/sort/sort.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_sort PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/sort/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_sort)

add_executable(bots_sparselu benchmarks/bots/sparselu/sparselu_single/sparselu.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_sparselu PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/sparselu/sparselu_single/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_sparselu)

add_executable(bots_strassen benchmarks/bots/strassen/strassen.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_strassen PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/strassen/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_strassen)

add_executable(bots_uts benchmarks/bots/uts/uts.c benchmarks/bots/uts/brg_sha1.c ${BotsCommon} wool.c wool.h ${numa_tools})
set_target_properties(bots_uts PROPERTIES COMPILE_FLAGS "-I. -Ibenchmarks/bots/uts/ -Ibenchmarks/bots/common/ -fopenmp -g")
add_bots_properties(bots_uts)