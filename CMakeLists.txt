cmake_minimum_required(VERSION 2.8)

IF(${CMAKE_PROJECT_NAME} STREQUAL "Torch")

  SET(TORCH_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

ELSE(${CMAKE_PROJECT_NAME} STREQUAL "Torch")

  string (REGEX REPLACE "(.*)lib/luarocks/rocks.*" "\\1" LUA_PREFIX "${CMAKE_INSTALL_PREFIX}" )

ENDIF(${CMAKE_PROJECT_NAME} STREQUAL "Torch")

install_files(/lua xlua.lua)
install_files(/lua OptionParser.lua)
