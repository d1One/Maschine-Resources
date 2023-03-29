------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/AccessibilityTextHelper"
require "Scripts/Shared/Pages/ControlPageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
AccessibleControlPage = class( 'AccessibleControlPage', ControlPageStudio )

------------------------------------------------------------------------------------------------------------------------

function AccessibleControlPage:__init(Controller, Name)

    ControlPageStudio.__init(self, Controller, Name)

end

------------------------------------------------------------------------------------------------------------------------

function AccessibleControlPage:getScreenButtonInfo(Index)

    local Info = PageMaschine.getScreenButtonInfo(self, Index)
    if not Info then
        return
    end

    if self.Controller:getShiftPressed() then

        if Index == 5 or Index == 6 then
            Info.SpeechName = "Move Plug-in " .. (Index == 5 and "Left" or "Right")
            Info.SpeechValue = AccessibilityTextHelper.getMovedPluginMessage()
            Info.SpeakValueInTrainingMode = false
            Info.SpeakNameInNormalMode = false

        elseif Index == 7 then
            local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
            Info.SpeechName = "Bypass Plug-in"
            Info.SpeechValue = FocusSlot ~= nil and not FocusSlot:getActiveParameter():getValue() and "ON" or "OFF"

        elseif Index == 8 then
            Info.SpeechName = "Remove Plug-in"
            Info.SpeechValue = ""
        end

    else

        if Index == 5 or Index == 6 then
            Info.SpeechName = (Index == 5 and "Previous" or "Next") .. " Plug-in"
            Info.SpeechValue = AccessibilityTextHelper.getFocusPluginMessage()
            Info.SpeakValueInTrainingMode = false
            Info.SpeakNameInNormalMode = false

       end

    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function AccessibleControlPage:getWheelPushInfo()

    return "Plug-in"

end