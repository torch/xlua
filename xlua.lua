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
--            methods to deal with the namespace
--
-- history: 
--     June 30, 2011, 4:54PM - creation
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
lua_print = glob.print
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
