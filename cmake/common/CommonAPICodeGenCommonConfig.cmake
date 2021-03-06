
set(COMMONAPI_CODEGEN_COMMAND_LINE commonAPICodeGen)
set(COMMONAPI_GENERATED_FILES_LOCATION FrancaGen)

find_package(PkgConfig REQUIRED)

pkg_check_modules(COMMON_API REQUIRED CommonAPI)
add_definitions(${COMMONAPI_CFLAGS_OTHER})
include_directories(${COMMONAPI_INCLUDE_DIRS})
link_directories(${COMMON_API_LIBRARY_DIRS})

set(FRANCA_IDLS_LOCATION include/franca_idls)
set(SERVICE_HEADERS_INSTALLATION_DESTINATION include/CommonAPIServices)
set(SERVICE_HEADERS_INSTALLED_LOCATION ${CMAKE_INSTALL_PREFIX}/${SERVICE_HEADERS_INSTALLATION_DESTINATION})


macro(get_library_name variableName interface)
    set(LIBRARY_NAME ${interface}_CommonAPI)
    string(REGEX REPLACE "/" "_" LIBRARY_NAME ${LIBRARY_NAME})
    set( ${variableName} ${LIBRARY_NAME})
endmacro()


# Macro: prepare_fidl_temporary_location
#
# Copies interface files to a temporary location (where the generated CommonAPI code is located).
# The interface files are picked up from the locations pointed to by the "fidl include paths" passed
# by the user.
#
# This macro is intended to become redundant when upstream supports include paths in the tooling
# directly. When that happens, the intention is to keep the user API, e.g. "add_commonapi_service"
# untouched and therefore this macro serves as a temporary fix to have the 'same' behaviour.
#
# TODO:
#       * Handle whole trees, e.g. when subdirectories contains the interface files
#
macro(prepare_fidl_temporary_location deploymentFile idlFiles fidl_include_paths)

    # Find all fidl files in include directories
    foreach(include_path ${fidl_include_paths})
        # Use absoulte path if one was provided...
        if(IS_ABSOLUTE ${include_path})
            set(FULL_INCLUDE_PATH ${include_path})
        # ... otherwise construct one based on the relative path
        else()
            set(FULL_INCLUDE_PATH ${CMAKE_INSTALL_PREFIX}/${FRANCA_IDLS_LOCATION}/${include_path})
            # COMMONAPI_INTEGRATION_SYSROOT should be set by e.g. a yocto recipe to point out the
            # location of the build
            if(DEFINED COMMONAPI_INTEGRATION_SYSROOT)
                set(FULL_INCLUDE_PATH ${COMMONAPI_INTEGRATION_SYSROOT}/${FULL_INCLUDE_PATH})
            endif(DEFINED COMMONAPI_INTEGRATION_SYSROOT)
        endif()
        file(GLOB FIDL_FILES_HERE ${FULL_INCLUDE_PATH}/*.fidl)
        set(FIDL_FILES "${FIDL_FILES};${FIDL_FILES_HERE}")
    endforeach(include_path)

    # The files can't be placed in the same location as the generated code, otherwise included files will
    # be intalled twice.
    set(TEMPORARY_FILES_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/temporary-fidl-includes/)

    # Copy all fidl files from include path(s) to temporary location
    file(COPY ${FIDL_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION})
#     message("### copied ${FIDL_FILES} to ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION}")

    # Copy deployment file to the same tempoarary location as the included fidl files
    file(COPY ${deploymentFile} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION})
#     message("### copied ${deploymentFile} to ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION}")

    # Copy fidl file to the same tempoarary location as the included fidl files
    file(COPY ${idlFiles} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION})
#     message("### copied ${idlFile} to ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION}")

#     set(INCLUDED_FIDL_FILES_DIR ${COMMONAPI_GENERATED_FILES_LOCATION})

    # Set a flag that a temporary location will be used
    set(USE_TEMPORARY_FIDL_LOCATION TRUE)
endmacro()


macro(get_generated_files_list VARIABLE_NAME deploymentFile codegenerators)

    # Check if temporary location is to be used
    if(USE_TEMPORARY_FIDL_LOCATION)
        get_filename_component(DEPLOYMENT_FILE ${deploymentFile} NAME)
        message("List Command : ${COMMONAPI_CODEGEN_COMMAND_LINE} -l -f ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION}/${DEPLOYMENT_FILE} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}")
        execute_process(
            COMMAND ${COMMONAPI_CODEGEN_COMMAND_LINE} -l -f ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION}/${DEPLOYMENT_FILE} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}
            OUTPUT_VARIABLE ${VARIABLE_NAME} OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    else(USE_TEMPORARY_FIDL_LOCATION)
        message("List Command : ${COMMONAPI_CODEGEN_COMMAND_LINE} -l -f ${deploymentFile} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}")
        execute_process(
            COMMAND ${COMMONAPI_CODEGEN_COMMAND_LINE} -l -f ${deploymentFile} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}
            OUTPUT_VARIABLE ${VARIABLE_NAME} OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif(USE_TEMPORARY_FIDL_LOCATION)

    message(STATUS "List of generated files : ${${VARIABLE_NAME}}")
endmacro()


macro(add_generated_files_command GENERATED_FILES deploymentFile codegenerators)

    # Check if temporary location is to be used
    if(USE_TEMPORARY_FIDL_LOCATION)
        get_filename_component(DEPLOYMENT_FILE ${deploymentFile} NAME)
        message("Generate Command : ${COMMONAPI_CODEGEN_COMMAND_LINE} -f ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION}/${DEPLOYMENT_FILE} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}")
        execute_process(
            COMMAND ${COMMONAPI_CODEGEN_COMMAND_LINE} -f ${CMAKE_CURRENT_BINARY_DIR}/${TEMPORARY_FILES_LOCATION}/${DEPLOYMENT_FILE} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}
            OUTPUT_VARIABLE ${VARIABLE_NAME} OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    else(USE_TEMPORARY_FIDL_LOCATION)
        message("Generate Command : ${COMMONAPI_CODEGEN_COMMAND_LINE} -f ${deploymentFile} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}")
        execute_process(
            COMMAND ${COMMONAPI_CODEGEN_COMMAND_LINE} -f ${deploymentFile} -o ${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} ${codegenerators}
            OUTPUT_VARIABLE ${VARIABLE_NAME} OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif(USE_TEMPORARY_FIDL_LOCATION)

    include_directories(${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION})
endmacro()


# TODO: We should not re-install code that has been generated based in included fidl files.
#
macro(install_franca_idl interfaceName deploymentFile deploymentFileDestinationName idlFiles)
    install(FILES ${idlFiles} DESTINATION ${FRANCA_IDLS_LOCATION}/${interfaceName}/.. )
    message("configure file ${deploymentFile} ${CMAKE_CURRENT_BINARY_DIR}/${deploymentFileDestinationName}")
    configure_file(${deploymentFile} ${CMAKE_CURRENT_BINARY_DIR}/${deploymentFileDestinationName} @ONLY)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${deploymentFileDestinationName} DESTINATION ${FRANCA_IDLS_LOCATION}/${interfaceName}/.. )
endmacro()


# Use a previously generated CommonAPI proxy/stub library
#
# NOTE: Deprecated! Use 'use_commonapi_service_stub' or 'use_commonapi_service_proxy'
macro(use_commonapi_service variableName interface)

    get_library_name(LIBRARY_NAME ${interface})
    set(PKGCONFIG_FILENAME ${LIBRARY_NAME})

    pkg_check_modules(${PKGCONFIG_FILENAME}_PKG REQUIRED ${PKGCONFIG_FILENAME})
    add_definitions(${${PKGCONFIG_FILENAME}_PKG_CFLAGS})
    link_directories(${${PKGCONFIG_FILENAME}_PKG_LIBRARY_DIRS})

    # See below why "--no-as-needed" is needed here
    set(${variableName}_LIBRARIES -Wl,--no-as-needed ${${PKGCONFIG_FILENAME}_PKG_LIBRARIES} -Wl,--as-needed)
    set(${variableName}_PKGCONFIG_FILENAME ${PKGCONFIG_FILENAME})

    message("CommonAPI libraries for ${interface} : ${${variableName}_LIBRARIES}")

endmacro()


macro(use_commonapi_service_stub variableName interface)
    use_commonapi_service(${variableName} ${interface})
endmacro(use_commonapi_service_stub)


macro(use_commonapi_service_proxy variableName interface)
    use_commonapi_service(${variableName} ${interface})
endmacro(use_commonapi_service_proxy)


# Warning: the pkg_check_modules macro seems to remove the libraries specified
# between "--no-as-needed" and "--as-needed" in pkg-config files, so we need to add the library twice.
# Once with "--no-as-needed" and once without!
#
# Generates and installs a pkg-config file
macro(add_commonapi_pkgconfig interface)
    if(INSTALL_PKGCONFIG_UNINSTALLED_FILE)
        set(DEVELOPMENT_INCLUDE_PATH " -I${CMAKE_CURRENT_BINARY_DIR}/${COMMONAPI_GENERATED_FILES_LOCATION} #")
        set(DEVELOPMENT_LIBRARY_PATH " -L${CMAKE_CURRENT_BINARY_DIR} #" )
    else()
        set(DEVELOPMENT_INCLUDE_PATH "")
        set(DEVELOPMENT_LIBRARY_PATH "")
    endif()

    get_library_name(LIBRARY_NAME ${interface})
    set(PKGCONFIG_FILENAME ${LIBRARY_NAME}.pc)
    file(WRITE ${PROJECT_BINARY_DIR}/${PKGCONFIG_FILENAME} "prefix=${CMAKE_INSTALL_PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: ${interface} Common-API Service
Description: ${interface} Common-API Service
Version: 
Requires: CommonAPI
Libs: -Wl,--no-as-needed,-l${LIBRARY_NAME}_Backend,--as-needed -l${LIBRARY_NAME}_Backend -L\${libdir} ${DEVELOPMENT_LIBRARY_PATH}
Cflags: ${DEVELOPMENT_INCLUDE_PATH} -I\${includedir}/CommonAPIServices
")

    install(FILES ${PROJECT_BINARY_DIR}/${PKGCONFIG_FILENAME} DESTINATION lib/pkgconfig)

endmacro()
