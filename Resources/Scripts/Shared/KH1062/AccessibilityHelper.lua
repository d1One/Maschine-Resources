local AccessibilityTextHelper = require("Scripts/Shared/Helpers/AccessibilityTextHelper")

local AccessibilityHelper = {}

------------------------------------------------------------------------------------------------------------------------

function AccessibilityHelper.onShiftPressed(Model, Controller)

    if not Model:isAccessibilityEnabled() then
        return
    end
    if Model:isDoubleClickTimerRunning() then
        Model:zeroDoubleClickTimer()
        local NewTrainingMode = not Model:isTrainingMode()
        Controller.setAccessibilityTrainingMode(NewTrainingMode)
        Controller.say(AccessibilityTextHelper.getOnOffFieldText("Training mode", NewTrainingMode))
    else
        Model:restartDoubleClickTimer()
        Controller.say("Shift")
    end

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityHelper.sayIfTrainingModeElse(Model, Controller, Utterance, ElseFunc)

    if Model and Controller then
        if Model:isTrainingMode() then
            Controller.say(Utterance)
        elseif ElseFunc then
            ElseFunc()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityHelper.connectToApp(AccessibilityController, AccessibilityModel)

    local ControllerBackendImpls =
    {
        scheduleSynthesizerMessage = function(ShortUtterance, LongUtterance)
            App:getSpeechSynthesizer():scheduleMessage(ShortUtterance, LongUtterance)
        end,
        setTrainingMode = function(NewTrainingMode)
            NI.DATA.WORKSPACE.setAccessibilityTrainingMode(App, NewTrainingMode)
        end,
        setSpeakPreset = function(SpeakPreset)
            NI.DATA.WORKSPACE.setAccessibilitySpeakPreset(App, SpeakPreset)
        end,
        decrementDoubleClickTimer = function()
            AccessibilityModel:decrementDoubleClickTimer()
        end,
        setParameterPageCache = function(ParamCache)
            AccessibilityModel:setParameterPageCache(ParamCache)
        end
    }
    AccessibilityController.setBackendFuncs(ControllerBackendImpls)

    local ModelBackendImpls =
    {
        isAccessibilityEnabled= function()
            return App:getSpeechSynthesizer():getEnabled()
        end,
        isInTrainingMode = function()
            return NI.DATA.WORKSPACE.getAccessibilityTrainingMode(App)
        end,
        getSpeakPreset = function()
            return NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App)
        end
    }
    AccessibilityModel:setBackendFuncs(ModelBackendImpls)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityHelper.getChangedParameterTextFromPage(AccessibilityDataCache, NewSectionName, NewDisplayName)

    local FullPhrase = NewSectionName .. " " .. NewDisplayName

    local OnlySpeakChangedData = function()
        local PhraseToSpeak
        if AccessibilityDataCache.SectionName ~= NewSectionName then
            PhraseToSpeak = FullPhrase
        else
            PhraseToSpeak = NewDisplayName
        end
        return PhraseToSpeak
    end
    local Utterance = AccessibilityDataCache and OnlySpeakChangedData() or FullPhrase

    return Utterance

end

------------------------------------------------------------------------------------------------------------------------

function AccessibilityHelper.sayIfBusyStateIsBlocking(AccessibilityController, BusyState)

    if BusyState == NI.HW.BUSY_SEE_SW or BusyState == NI.HW.BUSY_YES_NO then
        AccessibilityController.say("A dialog box has opened in the software")
    end

end

return AccessibilityHelper
