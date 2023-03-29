local class = require 'Scripts/Shared/Helpers/classy'
ScenePatternHelper = class( 'ScenePatternHelper' )

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.isIdeaSpace()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getArrangerState():isViewInIdeaSpace() and ArrangerHelper.isIdeaSpaceFocused()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.isModeAndViewInSync()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and not math.xor(Song:getArrangerState():isViewInIdeaSpace(), ArrangerHelper.isIdeaSpaceFocused())

end

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.updateWheelButtonLEDs()

    local CanUp = ScenePatternHelper.isIdeaSpace() and PatternHelper.hasPrevNextPattern(false, true)
    local CanDown = ScenePatternHelper.isIdeaSpace() and PatternHelper.hasPrevNextPattern(true, true)
        and PatternHelper.getNumPatternsInFocusedGroup() > 0

    local FocusGroup = ScenePatternHelper.isIdeaSpace() and NI.DATA.StateHelper.getFocusGroup(App) or nil

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App) + 1
    local CanLeft = GroupIndex > 1
    local CanRight = GroupIndex < MaschineHelper.getFocusSongGroupCount()

    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, CanUp, LEDColors.WHITE)
    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, CanDown, LEDColors.WHITE)
    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, LEDColors.WHITE)
    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, LEDColors.WHITE)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.onWheelButton(Pressed)

    if Pressed and ScenePatternHelper.isIdeaSpace() then
        NI.DATA.TransportAccess.restartTransport(App)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.onWheelDirection(Pressed, Button)

    if not Pressed then
        return
    end

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    if ScenePatternHelper.isIdeaSpace() and (Button == NI.HW.BUTTON_WHEEL_UP or Button == NI.HW.BUTTON_WHEEL_DOWN) then
       PatternHelper.focusPrevNextPattern(Button == NI.HW.BUTTON_WHEEL_DOWN, true)

    elseif (Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT) and GroupIndex ~= NPOS then
        MaschineHelper.setFocusGroup((GroupIndex + 1) + (Button == NI.HW.BUTTON_WHEEL_LEFT and -1 or 1))
    end
end

------------------------------------------------------------------------------------------------------------------------

function ScenePatternHelper.onWheel(Value)

    if ScenePatternHelper.isIdeaSpace() then
        PatternHelper.focusPrevNextPattern(Value > 0, true)
    end

end