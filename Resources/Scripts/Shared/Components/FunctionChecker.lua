local FunctionChecker = {}

------------------------------------------------------------------------------------------------------------------------

function FunctionChecker.checkFunctionsExist(Callbacks, ExpectedFunctionNames)

    for _, ExpectedFunctionName in pairs(ExpectedFunctionNames) do
        if Callbacks[ExpectedFunctionName] == nil then
            debug.printCallStack()
            error ("Callback " .. ExpectedFunctionName .. " missing")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

return FunctionChecker
