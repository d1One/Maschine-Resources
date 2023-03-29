------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/SamplingHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageMikroMK3 = class( 'SamplingPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------
function SamplingPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "SamplingPageMikroMK3", Controller)
    self.Tick = 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:updateScreen()

    if self:isEditParameterFocused() then
        self:updateScreenEdit()
    else
        self:updateScreenRecord()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:onControllerTimer()

    if SamplingPageMikroMK3:isRecordParameterFocused() then
       self:updateScreenRecord()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:isRecordParameterFocused()

    local FocusedParameter = NHLController:focusedParameter()
    return FocusedParameter and FocusedParameter:name() == "Record Sample"

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:isEditParameterFocused()

    local Parameter = NHLController:focusedParameter()
    local ParameterName = Parameter and Parameter:name() or ""
    return ParameterName == "Start" or ParameterName == "End"

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:updateScreenRecord()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    if not Recorder then
        return
    end

    local IconAttribute = self.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL) and "button_pressed" or "button_unpressed"
    self.Screen:showTextInBottomRow():setBottomRowIcon(IconAttribute)

    self.Tick = self.Tick + 1
    local Dots = {"", ".", "..", "..."}
    local DotString = Dots[(math.floor(self.Tick/30) % 4) + 1]
    local TopText = ""
    local BottomText = ""

    if Recorder:isStopped() then

        TopText = "Record "..(SamplingHelper.isLoopArmed() and "Loop" or "Sample")
        BottomText = "Start"

    elseif Recorder:isWaiting() then

        TopText = "Waiting"..DotString
        BottomText = "Cancel"

    elseif Recorder:isRecording() then

        TopText = "Recording"..DotString
        BottomText = "Stop"

    end

    self.Screen:setTopRowText(TopText)
    self.Screen:setBottomRowText(BottomText)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMikroMK3:updateScreenEdit()

    local FocusedParameter = NHLController:focusedParameter()
    local Value = FocusedParameter:maschineParameter() and FocusedParameter:maschineParameter():getValue() or "-"

    self.Screen:setBottomRowIcon("")
        :setTopRowText("Play Range")
        :showParameterInBottomRow()
        :setParameterName(FocusedParameter:name())
        :setParameterValue(Value)
end

------------------------------------------------------------------------------------------------------------------------
