#[=====================================[.rst
genlink
-------

CMake wrapper around the genlink.py script for fetching device definitions and information.
Assumes that `Libopencm3_ROOT_DIR` is defined by the time this is included.

Result variables
^^^^^^^^^^^^^^^^

``_LOCM3_DATA_FILE``
  The location of the genlink device data file.
``_LOCM3_DEVICE_FAMILY``
  The device family (like stm32f0 etc.) as determined by the device data.
``_LOCM3_DEVICE_SUBFAMILY``
  The device subfamily (like stmf071cbt6 etc.) as determined by the device data.
``_LOCM3_DEVICE_CPU``
  The CPU type (like cortex-m0 etc.) as determined by the device data.
``_LOCM3_DEVICE_FPU``
  The FPU type (like soft etc.) as determined by the device data.
``_LOCM3_ARCH_FLAGS``
  The OCM3 specific architecture flags for invoking the system compiler.
]=====================================]

include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.18)

find_program(PYTHON_EXE
        /usr/bin/python3
        /usr/bin/python
        python3
        python)
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

_genlink_obtain(${LOCM3_DEVICE} FAMILY _LOCM3_DEVICE_FAMILY)
_genlink_obtain(${LOCM3_DEVICE} SUBFAMILY _LOCM3_DEVICE_SUBFAMILY)
_genlink_obtain(${LOCM3_DEVICE} CPU _LOCM3_DEVICE_CPU)
_genlink_obtain(${LOCM3_DEVICE} FPU _LOCM3_DEVICE_FPU)
_genlink_obtain(${LOCM3_DEVICE} DEFS _LOCM3_DEVICE_DEFS)
string(REPLACE " " ";" _LOCM3_DEVICE_DEFS ${_LOCM3_DEVICE_DEFS})

if ("${_LOCM3_DEVICE_FAMILY}" STREQUAL "")
    message(FATAL_ERROR "${LOCM3_DEVICE} not found in ${_LOCM3_DATA_FILE}")
endif ()

set(_LOCM3_THUMB_DEVS
        cortex-m0
        cortex-m0plus
        cortex-m3
        cortex-m4
        cortex-m7)

set(_LOCM3_ARCH_FLAGS "")
list(APPEND _LOCM3_ARCH_FLAGS -mcpu=${_DEVICE_CPU})

# If the hosting toolchain uses Clang, we need to determine the target triple to invoke the preprocessor
if (CMAKE_C_COMPILER_ID STREQUAL "Clang")
    if ("${_LOCM3_DEVICE_CPU}" STREQUAL "cortex-m0" OR "${_LOCM3_DEVICE_CPU}" STREQUAL "cortex-m0plus")
        list(APPEND _LOCM3_ARCH_FLAGS --target=thumbv6m-none-eabi)
    elseif ("${_LOCM3_DEVICE_CPU}" STREQUAL "cortex-m3")
        list(APPEND _LOCM3_ARCH_FLAGS --target=thumbv7m-none-eabi)
    elseif ("${_LOCM3_DEVICE_CPU}" STREQUAL "cortex-m4" OR "${_LOCM3_DEVICE_CPU}" STREQUAL "cortex-m7")
        list(APPEND _LOCM3_ARCH_FLAGS --target=thumbv7em-none-eabi)
    endif ()
endif ()

if ("${_LOCM3_DEVICE_CPU}" IN_LIST _LOCM3_THUMB_DEVS)
    list(APPEND _LOCM3_ARCH_FLAGS -mthumb)
endif ()

if ("${_LOCM3_DEVICE_FPU}" STREQUAL "soft")
    list(APPEND _LOCM3_ARCH_FLAGS -msoft-float)
elseif ("${_LOCM3_DEVICE_FPU}" STREQUAL "hard-fpv4-sp-d16")
    list(APPEND _LOCM3_ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv4-sp-d16)
elseif ("${_LOCM3_DEVICE_FPU}" STREQUAL "hard-fpv5-sp-d16")
    list(APPEND _LOCM3_ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv5-sp-d16)
else ()
    message(FATAL_ERROR "No match for the FPU flags")
endif ()