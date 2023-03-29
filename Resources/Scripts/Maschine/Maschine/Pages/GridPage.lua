------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/GridPageBase"

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Maschine/Helper/GridHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPage = class( 'GridPage', GridPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function GridPage:__init(Controller)

    GridPageBase.__init(self, "GridPage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function GridPage:setupScreen()

    self.Screen = ScreenWithGrid(self)

    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"GRID", "PERFORM", "PATTERN", "STEP", "v", "v", "v", "v"})
    self.Screen.ScreenButton[1]:style("GRID", "HeadPin")
    self.Screen.ScreenButton[2]:style("PERFORM", "HeadTab")
    self.Screen.ScreenButton[3]:style("ARRANGE", "HeadTab")
    self.Screen.ScreenButton[4]:style("STEP", "HeadTab")

	-- Parameter bar
	self.Screen:addParameterBar(self.Screen.ScreenLeft)
	self.ParameterHandler.SectionWidgets = {}

end

------------------------------------------------------------------------------------------------------------------------

function GridPage:onWheel()

	if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
		self.Controller.QuickEdit.NumPadPressed > 0 then
		return true
	end

end

------------------------------------------------------------------------------------------------------------------------

function GridPage:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function GridPage:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function GridPage:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

