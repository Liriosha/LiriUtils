-- verbosity.lua
--
-- Usage:
--   local verbose = require(verbosity)
--   verbose.enabled = true
--
--   local log = verbose("test")
--   log("hello world!")
--
-- Output:
--   (5) [test.main] hello world!

local verbose = setmetatable({},{
    __call = function(self,debugname)
        return function(...)
            if self.enabled then
                local name,line = debug.info(2,"nl")
                if name == "" then
                    name="main"
                end
                print("(" .. line .. ") [" .. debugname .. "." .. name .. "]", ...)
            end
        end
    end
})
return verbose