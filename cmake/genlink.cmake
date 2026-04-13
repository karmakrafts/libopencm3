#[=====================================[.rst
genlink
-------

CMake wrapper around the genlink.py script for fetching device definitions and information.
Assumes that `Libopencm3_ROOT_DIR` is defined by the time this is included.

]=====================================]

cmake_minimum_required(VERSION 3.18)

include_guard(GLOBAL)
find_program(PYTHON_EXE python)

if ("${PYTHON_EXE}" STREQUAL "PYTHON_EXE-NOTFOUND")
    message(FATAL_ERROR "Libopencm3 MCU support requires Python!")
endif ()

set(_LOCM3_DATA_FILE ${Libopencm3_ROOT_DIR}/ld/devices.data)

if (NOT EXISTS ${_LOCM3_DATA_FILE})
    message(FATAL_ERROR "Unable to find device data file ${_LOCM3_DATA_FILE}!")
endif ()

function(_genlink_obtain DEVICE PROPERTY OUTPUT)
    execute_process(COMMAND
            ${PYTHON_EXE} ${Libopencm3_ROOT_DIR}/scripts/genlink.py ${_LOCM3_DATA_FILE} ${DEVICE} ${PROPERTY}
            OUTPUT_VARIABLE OUT_DATA
            RESULT_VARIABLE SUCCESS
    )
    if ("${SUCCESS}" EQUAL "0")
        message(DEBUG ">> ${OUT_DATA}")
        set("${OUTPUT}" "${OUT_DATA}" PARENT_SCOPE)
    else ()
        message(FATAL_ERROR "Unable to obtain ${PROPERTY} for device ${DEVICE}!")
    endif ()
endfunction()