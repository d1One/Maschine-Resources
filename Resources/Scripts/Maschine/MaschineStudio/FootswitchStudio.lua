------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FootswitchStudio = class( 'FootswitchStudio' )

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:__init(Controller)

	self.Controller = Controller

	self.NumPedals = 0

	-- this is to update the pedal state a second or so after initialisation
	self.ActivationCountdown = 60

end

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:updatePedalState()

	self.NumPedals = NHLController:getNumConnectedPedals()

end

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:onTimer()

	if self.ActivationCountdown > 0 then
		self.ActivationCountdown = self.ActivationCountdown - 1
		if self.ActivationCountdown == 0 then
			self:updatePedalState()
		end
	end

end

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:onFootswitchDetect(Index, State)

	self.ActivationCountdown = 60

end

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:onFootswitchTip(Index, State)

	if self.ActivationCountdown > 0 or not State then
		return
	end

	-- only record toggle if we have 2 mono switches
	if self.NumPedals == 2 and Index == 2 then
		self.Controller.TransportSection:onRecord(true, false)
	else
		self.Controller.TransportSection:onPlay(true)
	end

end

------------------------------------------------------------------------------------------------------------------------

function FootswitchStudio:onFootswitchRing(Index, State)

	if self.ActivationCountdown > 0 or not State then
		return
	end

	self.Controller.TransportSection:onRecord(true, false)

end

------------------------------------------------------------------------------------------------------------------------
