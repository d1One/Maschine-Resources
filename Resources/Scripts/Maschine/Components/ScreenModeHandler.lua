------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenModeHandler = class( 'ScreenModeHandler' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:__init(ScreenModes, DefaultIndex)

    -- widgets for name / value
    self.Modes = ScreenModes
    self.Index = DefaultIndex

    self:incrementMode(0)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:update()
end

------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:incrementMode(Delta)

	self.Index = math.wrap(self.Index + Delta, 1, #self.Modes)
	self:update()
end

------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:getCurrentMode()

	return self.Modes[self.Index]
end

------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:setMode(Mode)

	for Idx, ModeName in pairs(self.Modes) do
		if ModeName == Mode then
			self.Index = Idx
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

function ScreenModeHandler:getMode(Index)

	if Index >= 1 and Index <= #self.Modes then
		return self.Modes[Index]
	end

	return nil
end

------------------------------------------------------------------------------------------------------------------------
