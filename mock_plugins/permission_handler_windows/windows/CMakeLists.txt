cmake_minimum_required(VERSION 3.14)
project(permission_handler_windows)

set(PLUGIN_NAME "permission_handler_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "permission_handler_windows_plugin.cpp"
)

target_include_directories(${PLUGIN_NAME} PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  PUBLIC_HEADER "include/permission_handler_windows/permission_handler_windows_plugin.h"
  OUTPUT_NAME "permission_handler_windows_plugin"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
