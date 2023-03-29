require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridQuickEdit = class( 'GridQuickEdit' )

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:__init(Controller)

    self.Controller       = Controller
    self.ParameterHandler = ParameterHandlerJam(self)
    self.Enabled          = false

    -- Track if the user changed the grid in quickEdit mode
    self.ValueEdited = false

    -- { "1/4" , "1/8" , "1/16" , "1/32" }
    self.QuickEditIndices = { 2 , 3 , 4 , 5 }

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:setEnabled(Enabled)

    if Enabled then
        self.ValueEdited = false
        NHLController:setSceneButtonMode(NI.HW.SCENE_BUTTON_MODE_GRID_EDIT)
    else
        NHLController:resetSceneButtonMode()
        if self.ValueEdited and JamHelper.isJamOSOVisible(NI.HW.OSO_GRID) then
            self.ParameterHandler:hideOSO()
        end
    end

    self.Enabled = Enabled

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:isEnabled()

    return self.Enabled

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:isIndexValid(Index)

    local QuickEditListSize = #self.QuickEditIndices
    return Index >= 0 and Index <= QuickEditListSize

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:onSceneButton(Index, Pressed)

    if self.Enabled and Pressed then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song and self:isIndexValid(Index) then

            local SnapParam = Song:getPatternEditorSnapParameter()
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, SnapParam, self.QuickEditIndices[Index])
            self.ValueEdited = true

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:onTimer()

    -- if the the grid oso gets closed by another class, disable quick edit
    if self.Enabled and not JamHelper.isJamOSOVisible(NI.HW.OSO_GRID) then
        self:setEnabled(false)
    end

    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:updateLEDs()

    if self.Enabled then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then

            local FocusSnap = Song:getPatternEditorSnapParameter():getValue()
            LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0,
                function(Index) return self:getLEDState(Index, FocusSnap) end,
                function(Index) return LEDColors.WHITE end)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function GridQuickEdit:getLEDState(Index, FocusSnap)

    local Enabled = self:isIndexValid(Index)
    local Focused = FocusSnap == self.QuickEditIndices[Index]

    return Focused, Enabled

end

------------------------------------------------------------------------------------------------------------------------


