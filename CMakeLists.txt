cmake_minimum_required(VERSION 2.8)

string (REGEX REPLACE "(.*)lib/luarocks/rocks.*" "\\1" LUA_PREFIX "${CMAKE_INSTALL_PREFIX}" )

install_files(/lua xlua.lua)
install_files(/lua OptionParser.lua)
