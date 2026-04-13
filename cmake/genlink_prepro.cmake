#[=====================================[.rst
genlink_prepro
--------------

CMake wrapper around the system compiler preprocessor,
used to generate linker scripts with genlink data.
]=====================================]

include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.18)

include(genlink)

function(_genlink_preprocess TEMPLATE SCRIPT RESULT)
    message(STATUS "Invoking ${CMAKE_C_COMPILER} ${_LOCM3_ARCH_FLAGS} ${_LOCM3_DEVICE_DEFS} -P -E ${TEMPLATE} -o ${SCRIPT}")
    execute_process(COMMAND ${CMAKE_C_COMPILER}
            ${_LOCM3_ARCH_FLAGS} ${_LOCM3_DEVICE_DEFS}
            -P -E ${TEMPLATE}
            -o ${SCRIPT}
            RESULT_VARIABLE ${RESULT})
endfunction()