
package = "sys"
version = "1.0-1"

source = {
   url = "sys-1.0-1.tgz"
}

description = {
   summary = "Provides a set of standard unixy tools",
   detailed = [[
         This package provides a set of standard unix
         tools, from file operators, to system clocks
         and so on.
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
      sys = "sys.lua",
      libsys = {
         sources = {"sys.c"}
         --libraries = {"date"},
         --incdirs = {"$(LIBDATE_INCDIR)"},
         --libdirs = {"$(LIBDATE_LIBDIR)"}
      }
   }
}
