local M = {}

local testModule = require('simple-nvim-plugin/testModule')

function M.test()
  print('hello world');
end

function M.callModule(str)
  testModule.test(str)
end

return M
