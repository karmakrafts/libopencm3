#[=====================================[.rst
FindLibopencm3
--------------

Finds the Libopencm3 library suitable for target device specified in variable
LOCM3_DEVICE. You have to set this variable to full name of your MCU before calling
find_package(Libopencm3) otherwise search will fail.


Components
^^^^^^^^^^

``hal``
  This component represents Libopencm3 HAL library. If this component is
  specified, then Libopencm3 library suitable for your target device will be
  found. If no such library is found, then package search will fail.

``ld``
  This component provides automatically generated linker script. If both `ld`
  and `hal` components are selected, then linker script is automatically used
  for imported targets and provided in generated linker options variable.

Imported targets
^^^^^^^^^^^^^^^^

``Libopencm3::Libopencm3``
  Libopencm3 HAL suitable for your MCU. This library automatically configures
  compiler to link using correct automatically generated linker script, exports
  include paths and compiler definitions.

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
include(FindPackageHandleStandardArgs)

set(_LOCM3_PKG_VARIABLES "")

# If no components are given, then we assume that both HAL and linker script
# should be handled. This is default happy path.
if (NOT Libopencm3_FIND_COMPONENTS)
    set(Libopencm3_FIND_COMPONENTS hal ld)
endif ()

if ("hal" IN_LIST Libopencm3_FIND_COMPONENTS)
    list(APPEND _LOCM3_PKG_VARIABLES
            Libopencm3_LIBRARY
            Libopencm3_LIBRARY_DIRS
            Libopencm3_INCLUDE_DIRS
            Libopencm3_DEFINITIONS
            Libopencm3_LINK_OPTIONS
    )
endif ()
if ("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
    list(APPEND _LOCM3_PKG_VARIABLES
            Libopencm3_LINKER_SCRIPT
    )
endif ()

if (NOT LOCM3_DEVICE)
    message(FATAL_ERROR "No target device selected! "
            "Please define variable LOCM3_DEVICE to contain *full* name of your MCU!")
endif ()

get_filename_component(Libopencm3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

include(genlink)

# Find library for given family or subfamily
set(_LOCM3_LIBNAME
        opencm3_${_DEVICE_FAMILY}
        opencm3_${_DEVICE_SUBFAMILY}
)

if ("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
    set(Libopencm3_LINKER_SCRIPT ${CMAKE_BINARY_DIR}/gen.${LOCM3_DEVICE}.ld)

    # If found, then generate the linker script
    execute_process(COMMAND ${CMAKE_C_COMPILER}
            ${_LOCM3_ARCH_FLAGS} ${_LOCM3_DEVICE_DEFS}
            -P -E ${Libopencm3_ROOT_DIR}/ld/linker.ld.S
            -o ${Libopencm3_LINKER_SCRIPT}
            RESULT_VARIABLE CPP_RESULT)
    if (NOT "${CPP_RESULT}" EQUAL "0")
        message(FATAL_ERROR "Unable to generate linker script for device ${LOCM3_DEVICE}")
    else ()
        set(Libopencm3_ld_FOUND TRUE)
    endif ()
endif ()

if ("hal" IN_LIST Libopencm3_FIND_COMPONENTS)
    _genlink_obtain(${LOCM3_DEVICE} CPPFLAGS Libopencm3_DEFINITIONS)
    foreach (LOCM3_CANDIDATE ${_LOCM3_LIBNAME})
        if (EXISTS ${Libopencm3_ROOT_DIR}/lib/lib${LOCM3_CANDIDATE}.a)
            # Provide exported variables
            set(Libopencm3_LIBRARY ${LOCM3_CANDIDATE})
            set(Libopencm3_LIBRARY_DIRS ${Libopencm3_ROOT_DIR}/lib)
            set(Libopencm3_INCLUDE_DIRS ${Libopencm3_ROOT_DIR}/include)
            set(Libopencm3_DEFINITIONS ${Libopencm3_DEFINITIONS} ${_LOCM3_ARCH_FLAGS})
            set(Libopencm3_LINK_OPTIONS -static -nostartfiles ${_LOCM3_ARCH_FLAGS})

            if ("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
                list(APPEND Libopencm3_LINK_OPTIONS -T${Libopencm3_LINKER_SCRIPT})
            endif ()

            if (NOT TARGET Libopencm3::Libopencm3)
                # Provide imported target, which wraps Libopencm3
                add_library(Libopencm3::Libopencm3 STATIC IMPORTED)
                set_target_properties(Libopencm3::Libopencm3
                        PROPERTIES
                        IMPORTED_LOCATION ${Libopencm3_LIBRARY_DIRS}/lib${Libopencm3_LIBRARY}.a
                        INTERFACE_INCLUDE_DIRECTORIES ${Libopencm3_INCLUDE_DIRS})
                set_property(TARGET Libopencm3::Libopencm3
                        PROPERTY INTERFACE_COMPILE_OPTIONS
                        ${Libopencm3_DEFINITIONS})
                set_property(TARGET Libopencm3::Libopencm3
                        PROPERTY INTERFACE_LINK_OPTIONS
                        ${Libopencm3_LINK_OPTIONS})
            endif ()
            set(Libopencm3_hal_FOUND TRUE)
            break()
        endif ()
    endforeach ()
endif ()

# Handle stuff such as REQUIRED, QUIET, etc.
find_package_handle_standard_args(Libopencm3
        FOUND_VAR Libopencm3_FOUND
        REQUIRED_VARS
        ${_LOCM3_PKG_VARIABLES}
        HANDLE_COMPONENTS
)