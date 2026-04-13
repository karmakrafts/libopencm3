#[=====================================[.rst
Libopencm3
----------

Automatically builds libopencm3 as part of your CMake project and exposes it with a FindLibopencm3 compatible API
when using FetchContent to include libopencm3.

Result variables
^^^^^^^^^^^^^^^^

``Libopencm3_FOUND``
  True if Libopencm3 was found. Provided by hal component.
``Libopencm3_LIBRARY``
  Library name needed to link Libopencm3. Provided by hal component.
``Libopencm3_DEFINITIONS``
  Compile definitions needed to use Libopencm3 correctly. Provided by hal
  component.
``Libopencm3_INCLUDE_DIRS``
  Path to include directories of Libopencm3. Provided by hal component.
``Libopencm3_LIBRARY_DIRS``
  Path to directory where Libopencm3 libraries are present. Provided by hal
  component.
``Libopencm3_LINK_OPTIONS``
  Linker options needed to use Libopencm3 correctly. Provided by hal component.
``Libopencm3_LINKER_SCRIPT``
  Path to automatically generated linker script suitable for target device.
  Provided by ld component.
``Libopencm3_ROOT_DIR``
  Root directory of Libopencm3. Always available.

]=====================================]

include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.18)

# Define all variables normally defined by find module

get_filename_component(Libopencm3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include(ProcessorCount)
include(genlink_prepro)
ProcessorCount(_LOCM3_NUM_THREADS)

_genlink_obtain(${LOCM3_DEVICE} CPPFLAGS Libopencm3_DEFINITIONS)
set(Libopencm3_DEFINITIONS ${Libopencm3_DEFINITIONS} ${_LOCM3_ARCH_FLAGS})

set(Libopencm3_FOUND TRUE)
set(Libopencm3_ld_FOUND TRUE)
set(Libopencm3_LIBRARY "opencm3_${_LOCM3_DEVICE_FAMILY}")
set(Libopencm3_LIBRARY_DIRS ${Libopencm3_ROOT_DIR}/lib)
set(Libopencm3_INCLUDE_DIRS ${Libopencm3_ROOT_DIR}/include)
set(Libopencm3_LINK_OPTIONS -static -nostartfiles ${_LOCM3_ARCH_FLAGS})
set(Libopencm3_LINKER_SCRIPT ${CMAKE_BINARY_DIR}/gen.${LOCM3_DEVICE}.ld)

# Load all available targets from the targets file
file(STRINGS "${Libopencm3_ROOT_DIR}/targets" _LOCM3_TARGETS)

# Use genlink to find the correct build target by family identification
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

# Add custom target for building and generating linker script

add_custom_target(Libopencm3_build
        COMMAND ${CMAKE_MAKE_PROGRAM} TARGETS=${_LOCM3_BUILD_TARGET} -j ${_LOCM3_NUM_THREADS}
        WORKING_DIRECTORY ${Libopencm3_ROOT_DIR})

_genlink_preprocess(${Libopencm3_ROOT_DIR}/ld/linker.ld.S
        ${Libopencm3_LINKER_SCRIPT}
        CPP_RESULT)
if (NOT "${CPP_RESULT}" EQUAL "0")
    message(FATAL_ERROR "Unable to generate linker script for device ${LOCM3_DEVICE}")
endif ()

# Add library

add_library(Libopencm3::Libopencm3 STATIC IMPORTED)
set_target_properties(Libopencm3::Libopencm3 PROPERTIES
        IMPORTED_LOCATION lib${Libopencm3_LIBRARY}.a
        INTERFACE_INCLUDE_DIRECTORIES ${Libopencm3_INCLUDE_DIRS})
set_property(TARGET Libopencm3::Libopencm3
        PROPERTY INTERFACE_COMPILE_OPTIONS
        ${Libopencm3_DEFINITIONS})
set_property(TARGET Libopencm3::Libopencm3
        PROPERTY INTERFACE_LINK_OPTIONS
        ${Libopencm3_LINK_OPTIONS})
add_dependencies(Libopencm3::Libopencm3 Libopencm3_build)