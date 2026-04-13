#[=====================================[.rst
Libopencm3
----------

Automatically builds libopencm3 as part of your CMake project and exposes it via FindLibopencm3.

]=====================================]

include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.18)

# Re-defined by find module, but we need it here BEFORE including the find module
get_filename_component(Libopencm3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include(ProcessorCount)
include(genlink)
ProcessorCount(_LOCM3_NUM_THREADS)

# Load all available targets from the targets file
file(STRINGS "${Libopencm3_ROOT_DIR}/targets" _LOCM3_TARGETS)

# Use genlink to find the correct build target by family identification
_genlink_obtain(${DEVICE} FAMILY _LOCM3_DEVICE_FAMILY) # Also kind of redundant but needed because of inclusion order
foreach (target IN LISTS _LOCM3_TARGETS)
    string(REPLACE "/" "" clean_target "${target}")
    if (NOT "${_LOCM3_DEVICE_FAMILY}" STREQUAL "${clean_target}")
        continue()
    endif ()
    set(_LOCM3_BUILD_TARGET "${clean_target}")
    break()
endforeach ()
if (NOT DEFINED _LOCM3_BUILD_TARGET)
    message(FATAL_ERROR "Could not determine libopencm3 build target from device family")
endif ()

# Add custom target for building

add_custom_target(Libopencm3_build
        COMMAND ${CMAKE_MAKE_PROGRAM} TARGETS=${_LOCM3_BUILD_TARGET} -j ${_LOCM3_NUM_THREADS}
        WORKING_DIRECTORY ${Libopencm3_ROOT_DIR})

# Include find module and add build target as dependency to exported library target

include(FindLibopencm3)
add_dependencies(Libopencm3::Libopencm3 Libopencm3_build)