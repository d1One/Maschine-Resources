------------------------------------------------------------------------------------------------------------------------
-- Page that displays Scale parameters.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"


local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageScale = class( 'ParameterPageScale', ParameterPageBase )


-----------------------------------------------------------------------------------------------------------------------
-- constants
-----------------------------------------------------------------------------------------------------------------------

local SECTION_ROOT_NOTE = 1

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ParameterPageScale:__init(Controller)

    ParameterPageBase.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageScale:updateScreen()

    self.PageField = "Scale"

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if not ScaleEngine or not Group then

        HELPERS.resetCachedParameters(App)

    else

        HELPERS.setCachedParameter(App, 0, ScaleEngine:getRootNoteParameter())
        HELPERS.setCachedParameter(App, 1, ScaleEngine:getChordModeIsChordSet() == false
                                           and ScaleEngine:getScaleBankParameter() or nil)
        HELPERS.setCachedParameter(App, 2, ScaleEngine:getChordModeIsChordSet() == false
                                           and ScaleEngine:getScaleParameter() or nil)
        HELPERS.setCachedParameter(App, 3, ScaleEngine:getChordModeIsChordSet() == false
                                           and NI.HW.getScaleEngineKeyModeParameter(App) or nil)
        HELPERS.setCachedParameter(App, 4, ScaleEngine:getChordModeParameter())
        HELPERS.setCachedParameter(App, 5, ScaleEngine:getChordModeParameter():getValue() ~= 0
                                           and ScaleEngine:getChordTypeAutomationParameter() or nil)
        HELPERS.setCachedParameter(App, 6, nil)
        HELPERS.setCachedParameter(App, 7, nil)

    end

    ParameterPageBase.updateScreen(self)

end


------------------------------------------------------------------------------------------------------------------------
-- Initialize the textual part of the display.
------------------------------------------------------------------------------------------------------------------------

function ParameterPageScale:updateParameterText(Section)

    ParameterPageBase.updateParameterText(self, Section)

    local Screen = NHLController:getScreen()
    Screen:setTextAlignment(Section, SCREEN.DISPLAY_FIRST_ROW, SCREEN.ALIGN_LEFT)

    if Section == 0 then
        Screen:setText(0, SCREEN.DISPLAY_FIRST_ROW, "Scale")
        return
    end

    Screen:setTextAlignment(Section, 0, SCREEN.ALIGN_LEFT)

    local Parameter = HELPERS.getCachedParameter(App, Section - 1)
    if Parameter then

        if Parameter:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then

            local ParamValue
            if Section == SECTION_ROOT_NOTE then
                local ScaleEngine = NI.DATA.getScaleEngine(App)
                ParamValue = ScaleEngine and ScaleEngine:getCurrentRootNoteNameKK() or ""
            else
                ParamValue = Parameter:getAsShortString(Parameter:getValue())
            end

            Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, ParamValue)

        else

            Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW,
                Parameter:getParameterInterface():getValueString())

        end

        -- MAS2-8249 hack
        if Section == 6 and PadModeHelper.isChordTypeMin7b5() then
            Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, "Min 7\226\153\1735")
        end

    else
        Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageScale:onEncoderEvent(EncoderID, Value)

    -- perform Value setting from script when autowriting
    local isAutoWriting = NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App) and
        MaschineHelper.isPlaying()

    if isAutoWriting then
        local Parameter = HELPERS.getCachedParameter(App, EncoderID)
        if Parameter then
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Parameter, Value, false, false)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageScale:onControllerTimer()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group == nil then

        local PageParameter = App:getWorkspace():getKKPerformPageParameter()
        NI.DATA.ParameterAccess.resetToDefaultNoUndo(App, PageParameter)

    end

end

------------------------------------------------------------------------------------------------------------------------
