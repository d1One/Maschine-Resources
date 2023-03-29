require "Scripts/Maschine/Components/QuickEditBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEdit = class( 'QuickEdit', QuickEditBase )

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:__init(Controller)

    QuickEditBase.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:setMode(Mode)

	NHLController:setJogWheelMode(Mode)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:resetMode(Mode)
end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:onVolumeEncoder(EncoderInc)

	if self.NumGroupPressed == 0 and self.NumPadPressed == 0 then
		self:setLevel(NI.DATA.LEVEL_TAB_SONG)
	end

    self:setMode(NI.HW.JOGWHEEL_MODE_VOLUME)
	self:onVolumeChange(EncoderInc, false)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:onTempoEncoder(EncoderInc)

	if self.NumGroupPressed == 0 and self.NumPadPressed == 0 then
		self:setLevel(NI.DATA.LEVEL_TAB_SONG)
	end

    self:setMode(NI.HW.JOGWHEEL_MODE_TEMPO)
	self:onTuneTempoChange(EncoderInc, false)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:onSwingEncoder(EncoderInc)

	if self.NumGroupPressed == 0 and self.NumPadPressed == 0 then
		self:setLevel(NI.DATA.LEVEL_TAB_SONG)
	end

    self:setMode(NI.HW.JOGWHEEL_MODE_SWING)
	self:onSwingChange(EncoderInc, false)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEdit:onWheel(Inc)

	local JogWheelMode = NHLController:getJogWheelMode()

	if JogWheelMode == NI.HW.JOGWHEEL_MODE_DEFAULT then
		return false
	end

	if self.NumGroupPressed == 0 and self.NumPadPressed == 0 then
		self.Level = NI.DATA.LEVEL_TAB_SONG
	end

	if JogWheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then
	    self:setMode(NI.HW.JOGWHEEL_MODE_VOLUME)
		self:onVolumeChange(Inc, true)

	elseif JogWheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then
	    self:setMode(NI.HW.JOGWHEEL_MODE_TEMPO)
		self:onTuneTempoChange(Inc, true)

	elseif JogWheelMode == NI.HW.JOGWHEEL_MODE_SWING then
 		self:setMode(NI.HW.JOGWHEEL_MODE_SWING)
		self:onSwingChange(Inc, true)
	end

	return true

end

------------------------------------------------------------------------------------------------------------------------
