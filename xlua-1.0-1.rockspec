
package = "xlua"
version = "1.0-1"

source = {
   url = "xlua-1.0-1.tgz"
}

description = {
   summary = "Provides a couple of functions to make the Lua shell better",
   detailed = [[
         + provides a better print() that goes through tables
         + provides clearall()/clear(var)/who() methods, a la Matlab
         + provides a simple progress bar to be happier when dealing with for loops :-)
   ]],
   homepage = "",
   license = "MIT/X11" -- or whatever you like
}

dependencies = {
   "lua >= 5.1"
   -- If you depend on other rocks, add them here
}

build = {
   type = "builtin",

   modules = {
      xlua = "xlua.lua",
   }
}
