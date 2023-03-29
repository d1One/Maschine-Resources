local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")

------------------------------------------------------------------------------------------------------------------------

local BUTTON_DOUBLE_CLICK_TIMEOUT = 20

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
AccessibilityModel = class( 'AccessibilityModel' )

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:__init()

    self.DoubleClickTimer = 0
    self.BackendFuncImpls =
    {
        isAccessibilityEnabled = nil,
        isInTrainingModel = nil,
        getSpeakPreset = nil
    }
    self.ParameterPageCache = nil

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:setBackendFuncs(BackendFuncImpls)

    FunctionChecker.checkFunctionsExist(BackendFuncImpls,
    {
        "isAccessibilityEnabled",
        "isInTrainingMode",
        "getSpeakPreset"
    })
    self.BackendFuncImpls = BackendFuncImpls

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:restartDoubleClickTimer()

    self.DoubleClickTimer = BUTTON_DOUBLE_CLICK_TIMEOUT

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:zeroDoubleClickTimer()

    self.DoubleClickTimer = 0

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:decrementDoubleClickTimer()

    if self.DoubleClickTimer > 0 then
        self.DoubleClickTimer = self.DoubleClickTimer - 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:isDoubleClickTimerRunning()

    return self.DoubleClickTimer > 0

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:isTrainingMode()

    return self:isAccessibilityEnabled() and
        (self.BackendFuncImpls.isInTrainingMode and self.BackendFuncImpls:isInTrainingMode() or false)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:isAccessibilityEnabled()

    return self.BackendFuncImpls.isAccessibilityEnabled and self.BackendFuncImpls:isAccessibilityEnabled() or false

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:getAccessibilitySpeakPreset()

    return self.BackendFuncImpls.getSpeakPreset and self.BackendFuncImpls:getSpeakPreset() or false

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityModel:setParameterPageCache(ParameterPageCache)

    self.ParameterPageCache = ParameterPageCache

end