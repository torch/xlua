CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)
FIND_PACKAGE(Torch REQUIRED)

SET(src)
SET(luasrc init.lua OptionParser.lua Profiler.lua)

ADD_TORCH_PACKAGE(xlua "${src}" "${luasrc}" "System")

