------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/GridHelper"

local ATTR_STEP_MODE = NI.UTILS.Symbol("StepMode")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPageMikro = class( 'GridPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "GridPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_TRANSPORT_GRID }

    self.GridMode = GridHelper.PERFORM -- modes are: GridHelper.PERFORM, GridHelper.ARRANGER, GridHelper.STEP

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"GRID"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"PERF", "ARNG", "STEP"}, "HeadTabRow", "HeadTab")

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[1]:setSelected(self.GridMode == GridHelper.PERFORM)
    self.Screen.ScreenButton[2]:setSelected(self.GridMode == GridHelper.ARRANGER)
    self.Screen.ScreenButton[3]:setSelected(self.GridMode == GridHelper.STEP)

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:updateParameters(ForceUpdate)

    -- set the current parameters
    self.ParameterHandler:setParameters( { GridHelper.getSnapParameter(self.GridMode) }, true )
    if self.GridMode == GridHelper.STEP then

        -- Add the On/Off Parameter
        self.ParameterHandler.Parameters[#self.ParameterHandler.Parameters + 1] =
            GridHelper.getSnapEnabledParameter(self.GridMode)

        -- Add the Nudge Parameter
        self.ParameterHandler.Parameters[#self.ParameterHandler.Parameters + 1] =
            GridHelper.getNudgeSnapParameter()

    elseif  self.GridMode == GridHelper.ARRANGER then

        -- Add the On/Off Parameter
        self.ParameterHandler.Parameters[#self.ParameterHandler.Parameters + 1] =
            GridHelper.getSnapEnabledParameter(self.GridMode)

        -- Add the Quick parameter
        if GridHelper.isSnapEnabled(self.GridMode) then
            self.ParameterHandler.Parameters[#self.ParameterHandler.Parameters + 1] =
                GridHelper.getQuickEnabledParameter()
        end

	    self.ParameterHandler.ParameterIndex = math.bound(
	        self.ParameterHandler.ParameterIndex, 1, #self.ParameterHandler.Parameters)
	end

    self.Screen.ParameterBar[1]:setActive(self.GridMode ~= GridHelper.PERFORM)   -- setActive because of styling issues
    self.Screen.ParameterBar[2]:setAttribute(ATTR_STEP_MODE, self.GridMode ~= GridHelper.PERFORM and "true" or "false")
    self.Screen.ParameterLabel[4]:setAttribute(ATTR_STEP_MODE, self.GridMode ~= GridHelper.PERFORM and "true" or "false")

	-- call base
	PageMikro.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handlers
------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:setMode(NewMode)

    if NewMode ~= self.GridMode then
	    self.GridMode = NewMode
	    self:updateScreens(true)
        self:updateParameters(true)
	end

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then
        if Idx == 1 then
            self:setMode(GridHelper.PERFORM)
        elseif Idx == 2 then
            self:setMode(GridHelper.ARRANGER)
        elseif Idx == 3 then
            self:setMode(GridHelper.STEP)
        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
