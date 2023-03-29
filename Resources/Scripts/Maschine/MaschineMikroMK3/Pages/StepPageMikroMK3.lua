------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageMikroMK3 = class( 'StepPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "StepPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen
        :showParameterInBottomRow()
        :cropParameterName()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:onStateFlagsChanged()

    StepHelper.syncPatternSegmentToModel()

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:updateScreen()

    self.Screen:setTopRowToFocusedSound()

    -- update bottom row focused pattern
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Pattern then
        local CurSegment = tostring(StepHelper.PatternSegment + 1)
        local NumSegments = tostring(StepHelper.getNumPatternSegments())
        self.Screen
            :setParameterName(Pattern:getNameParameter():getValue())
            :setParameterValue(CurSegment .. "/" .. NumSegments)
    else
        self.Screen
            :setParameterName("No Pattern")
            :setParameterValue("")
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:onControllerTimer()

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMikroMK3:onWheelEvent(Value)

    -- Any time the user changes the pattern section manually we want to turn off the follow parameters
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, App:getWorkspace():getFollowPlayPositionParameter(), false)
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, NHLController:getContext():getStepPageFollowParameter(), false)

    StepHelper.setPatternSegment(StepHelper.PatternSegment + Value)

end

------------------------------------------------------------------------------------------------------------------------
