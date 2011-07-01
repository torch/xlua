----------------------------------------------------------------------
--
-- Copyright (c) 2011 Clement Farabet
-- 
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------
-- description:
--     xlua - a package that provides a better Lua prompt, and a few
--            methods to deal with the namespace, argument unpacking
--            and so on...
--
-- history: 
--     June 30, 2011, 4:54PM - creation - Clement Farabet
----------------------------------------------------------------------

require 'os'
require 'sys'
require 'io'
require 'math'

-- new prompt
_G._PROMPT = 'xLua > '
_G._PROMPT2 = ' ... > '

-- remember startup variables (to protect them)
_G._protect_ = {'_protect_','xlua'}
for k,v in pairs(_G) do
   table.insert(_G._protect_, k)
end

local glob = _G
local pairs = pairs
local ipairs = ipairs
local _protect_ = _protect_

module 'xlua'

----------------------------------------------------------------------
-- better print function
----------------------------------------------------------------------
print = function(obj,...)
          if glob.type(obj) == 'table' then
              local mt = glob.getmetatable(obj)
              if mt and mt.__tostring__ then
                 glob.io.write(mt.__tostring__(obj))
              else
                 local tos = glob.tostring(obj)
                 local obj_w_usage = false
                 if tos and not glob.string.find(tos,'table: ') then
                    if obj.usage then
                       glob.io.write(obj.usage)
                       glob.io.write('\n\nFIELDS:\n')
                       obj_w_usage = true
                    else
                       glob.io.write(tos .. ':\n')
                    end
                 end
                 glob.io.write('{')
                 local tab = ''
                 local idx = 1
                 for k,v in pairs(obj) do
                    if idx > 1 then glob.io.write(',\n') end
                    if glob.type(v) == 'userdata' then
                       glob.io.write(tab .. '[' .. k .. ']' .. ' = <userdata>')
                    else
                       local tostr = glob.tostring(v):gsub('\n','\\n')
                       if #tostr>40 then
                          local tostrshort = tostr:sub(1,40) .. glob.sys.COLORS.none
                          glob.io.write(tab .. '[' .. k .. ']' .. ' = ' .. tostrshort .. ' ... ')
                       else
                          glob.io.write(tab .. '[' .. k .. ']' .. ' = ' .. tostr)
                       end
                    end
                    tab = ' '
                    idx = idx + 1
                 end
                 glob.io.write('}')
                 if obj_w_usage then
                    glob.io.write('')                    
                 end
              end
           else 
              glob.io.write(glob.tostring(obj))
           end
           if glob.select('#',...) > 0 then
              glob.io.write('    ')
              print(...)
           else
              glob.io.write('\n')
           end
        end
glob._print = glob.print
glob.print = print

----------------------------------------------------------------------
-- clear all globals
----------------------------------------------------------------------
clearall = function()
   for k,v in pairs(glob) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
	 if k == p then protected = true end
      end
      for p in pairs(glob.package.loaded) do
	 if k == p then lib = true end
      end
      if not protected then
	 glob[k] = nil
         if lib then glob.package.loaded[k] = nil end
      end
   end
   glob.collectgarbage()
end

----------------------------------------------------------------------
-- clear one variable
----------------------------------------------------------------------
clear = function(var)
   glob[var] = nil
   glob.collectgarbage()
end

----------------------------------------------------------------------
-- prints globals
----------------------------------------------------------------------
who = function()
   local user = {}
   local libs = {}
   for k,v in pairs(glob) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
	 if k == p then protected = true end
      end
      for p in pairs(glob.package.loaded) do
	 if k == p and p ~= '_G' then lib = true end
      end
      if lib then
         glob.table.insert(libs, k)
      elseif not protected then
	 user[k] =  glob[k]
      end
   end
   print('')
   print('Global Libs:')
   print(libs)
   print('')
   print('Global Vars:')
   print(user)
   print('')
end

----------------------------------------------------------------------
-- progress bar
----------------------------------------------------------------------
local barDone = true
local previous = -1
function progress(current, goal)
   local barLength = 77

   -- Compute percentage
   local percent = glob.math.floor(((current) * barLength) / goal)

   -- start new bar
   if (barDone and current == 1) then
      barDone = false
      previous = -1
   else
      glob.io.write('\r')
   end

   --if (percent ~= previous and not barDone) then
   if (not barDone) then
      previous = percent
      -- print bar
      glob.io.write(' [')
      for i=1,barLength do
         if (i < percent) then glob.io.write('=')
         elseif (i == percent) then glob.io.write('>')
         else glob.io.write('.') end
      end
      glob.io.write(']')
      -- go back to center of bar, and print progress
      for i=1,47 do glob.io.write('\b') end
      glob.io.write(' ', current, '/', goal, ' ')
      -- reset for next bar
      if (percent == barLength) then
         barDone = true
         glob.io.write('\n')
      end
      -- flush
      glob.io.flush()
   end
end

--------------------------------------------------------------------------------
-- prints an error with nice formatting. If domain is provided, it is used as
-- following: <domain> msg
--------------------------------------------------------------------------------
function error(message, domain, usage) 
   if domain then
      message = '<' .. domain .. '> ' .. message
   end
   local c = glob.sys.COLORS
   local col_msg = c.Red .. message .. c.none
   if usage then
      print(col_msg)
      glob.error(usage)
   else
      glob.error(col_msg)
   end
end
glob._error = error

--------------------------------------------------------------------------------
-- returns true if package is installed, rather than crashing stupidly :-)
--------------------------------------------------------------------------------
function installed(package) 
   local found = false
   local p = glob.package.path .. ';' .. glob.package.cpath
   for path in p:gfind('.-;') do
      path = path:gsub(';',''):gsub('?',package)
      if glob.sys.filep(path) then 
         found = true
         p = path
         break
      end
   end
   return found,p
end
function require(package) 
   if installed(package) then
      return glob.require(package)
   else
      print('warning: <' .. package .. '> could not be loaded (is it installed?)')
      return false
   end
end
glob._require = require

--------------------------------------------------------------------------------
-- standard usage function: used to display automated help for functions
--
-- @param funcname     function name
-- @param description  description of the function
-- @param example      usage example
-- @param ...          [optional] arguments
--------------------------------------------------------------------------------
function usage(funcname, description, example, ...)
   local c = COLORS
   local str = c.magenta .. '\n'
   local str = str .. '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
   str = str .. 'NAME:\n' .. funcname .. '\n'
   if description then
      str = str .. '\nDESC:\n' .. description .. '\n'
   end
   if example then
      str = str .. '\nEXAMPLE:\n' .. example .. '\n'
   end
   str = str .. '\nUSAGE:\n'

   -- named arguments:
   local args = {...}
   if args[1].arg then
      str = str .. funcname .. '{\n'
      for i,param in ipairs{...} do
         local key
         if param.req then
            key = '    ' .. param.arg .. ' = ' .. param.type
         else
            key = '    [' .. param.arg .. ' = ' .. param.type .. ']'
         end
         -- align:
         while key:len() < 40 do
            key = key .. ' '
         end
         str = str .. key .. '-- ' .. param.help 
         if param.default or param.default == false then
            str = str .. '  [default = ' .. tostring(param.default) .. ']'
         elseif param.defaulta then
            str = str .. '  [default == ' .. param.defaulta .. ']'
         end
         str = str.. '\n'
      end
      str = str .. '}\n'

   -- unnamed args:
   else
      str = str .. funcname .. '(\n'
      for i,param in ipairs{...} do
         local key
         if param.req then
            key = '    ' .. param.type
         else
            key = '    [' .. param.type .. ']'
         end
         -- align:
         while key:len() < 40 do
            key = key .. ' '
         end
         str = str .. key .. '-- ' .. param.help .. '\n'
      end
      str = str .. ')\n'
   end
   str = str .. '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
   str = str .. c.none
   return str
end

--------------------------------------------------------------------------------
-- standard argument function: used to handle named arguments, and 
-- display automated help for functions
--------------------------------------------------------------------------------
function unpack(args, funcname, description, ...)
   -- look at def, autogen example
   local defs = {...}
   local example
   if #defs > 1 then
      example = funcname .. '{' .. defs[2].arg .. '=' .. defs[2].type .. ', '
                                .. defs[1].arg .. '=' .. defs[1].type .. '}\n'
      example = example .. funcname .. '(' .. defs[1].type .. ',' .. ' ...)'
   end

   -- generate usage string
   local usage = usage(funcname, description, example, ...)

   -- get args
   local iargs = {}
   if #args == 0 then error(usage)
   elseif #args == 1 and type(args[1]) == 'table' and #args[1] == 0 then
      -- named args
      iargs = args[1]
   else
      -- ordered args
      for i = 1,select('#',...) do
         iargs[defs[i].arg] = args[i]
      end
   end

   -- check/set arguments
   local dargs = {}
   local c = COLORS
   for i,def in ipairs(defs) do
      -- is value requested ?
      if def.req and iargs[def.arg] == nil then
         print(c.Red .. 'missing argument: ' .. def.arg .. c.none)
         error(usage)
      end
      -- get value or default
      dargs[def.arg] = iargs[def.arg]
      if dargs[def.arg] == nil then
         dargs[def.arg] = def.default
      end
      if dargs[def.arg] == nil and def.defaulta then
         dargs[def.arg] = dargs[def.defaulta]
      end
      dargs[i] = dargs[def.arg]
   end

   -- return usage too
   dargs.usage = usage

   -- print doc ?
   if _PRINT_DOC_ then
      unpack_printdoc(dargs, funcname, description, ...)
   end

   -- return modified args
   return dargs,
   dargs[1], dargs[2], dargs[3], dargs[4], dargs[5], dargs[6], dargs[7], dargs[8], 
   dargs[9], dargs[10], dargs[11], dargs[12], dargs[13], dargs[14], dargs[15], dargs[16],
   dargs[17], dargs[18], dargs[19], dargs[20], dargs[21], dargs[22], dargs[23], dargs[24],
   dargs[25], dargs[26], dargs[27], dargs[28], dargs[29], dargs[30], dargs[31], dargs[32],
   dargs[33], dargs[34], dargs[35], dargs[36], dargs[37], dargs[38], dargs[39], dargs[40],
   dargs[41], dargs[42], dargs[43], dargs[44], dargs[45], dargs[46], dargs[47], dargs[48],
   dargs[49], dargs[50], dargs[51], dargs[52], dargs[53], dargs[54], dargs[55], dargs[56]
end

--------------------------------------------------------------------------------
-- standard argument function for classes: used to handle named arguments, and 
-- display automated help for functions
-- auto inits the self with usage
--------------------------------------------------------------------------------
function unpack_class(object, args, funcname, description, ...)
   local dargs = unpack(args, funcname, description, ...)
   for k,v in pairs(dargs) do
      if type(k) ~= 'number' then
         object[k] = v
      end
   end
end
