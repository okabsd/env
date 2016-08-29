local _ENV = require 'env' () -- in Lua 5.2+
-- setfenv(1, require 'env' ()) in Lua 5.1
-- --
-- Alternatives:
-- -- require 'env' (_ENV)
-- -- require 'env' { print = print }

-- Basic import
import 'module_name' -- Import the module with its own name, if not taken
module_name.do_something()

-- Forced import (end with a bang!)
import 'module_name!' -- Force import the module with its own name, even if taken
module_name.do_something()

-- Aliased import
import 'module_name' :as 'custom_name'
custom_name.do_something()

-- Flood import
import 'module_name' :use '*' -- Import all members of the module
do_something()

-- Specific imports
import 'module_name' :use { 'do_something' }
do_something()

-- Aliased specific imports
import 'module_name' :use { do_it = 'do_something' }
do_it()

-- Chaining multiple styles
-- -- (Arbitrary order.)
import 'module_name' :as 'my_mod' :use { do_anything = 'do_something' }
my_mod.do_somthing()
do_anything()
