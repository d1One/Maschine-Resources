local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")

------------------------------------------------------------------------------------------------------------------------

local AccessibilityController = {}

------------------------------------------------------------------------------------------------------------------------

local BackendFuncImpls =
{
    scheduleSynthesizerMessage = function(ShortUtterance, LongUtterance) end,
    setTrainingMode = function(NewTrainingMode) end,
    setSpeakPreset = function(SpeakPreset) end,
    decrementDoubleClickTimer = function() end
}

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.setBackendFuncs(Backend)

    FunctionChecker.checkFunctionsExist(Backend,
    {
        "scheduleSynthesizerMessage",
        "setTrainingMode",
        "setSpeakPreset",
        "decrementDoubleClickTimer",
        "setParameterPageCache"
    })
    BackendFuncImpls = Backend

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.sayExtended(ShortUtterance, LongUtterance)

    BackendFuncImpls.scheduleSynthesizerMessage(ShortUtterance, LongUtterance)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.say(ShortUtterance)

    AccessibilityController.sayExtended(ShortUtterance, "")

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.onTimerNotification()

    BackendFuncImpls.decrementDoubleClickTimer()

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.setAccessibilityTrainingMode(NewTrainingMode)

    BackendFuncImpls.setTrainingMode(NewTrainingMode)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.setAccessibilitySpeakPreset(SpeakPreset)

    BackendFuncImpls.setSpeakPreset(SpeakPreset)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityController.setParameterPageCache(ParameterPageCache)

    BackendFuncImpls.setParameterPageCache(ParameterPageCache)

end

------------------------------------------------------------------------------------------------------------------------

return AccessibilityController
