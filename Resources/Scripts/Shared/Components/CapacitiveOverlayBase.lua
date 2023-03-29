require "Scripts/Shared/Helpers/CapacitiveHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
CapacitiveOverlayBase = class( 'CapacitiveOverlayBase' )

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:__init(Controller)

    self.Controller = Controller

    -- the focus cap, there can be a delay before it is reset, after the user untouched the cap
    self.CachedFocusCap = nil
    self.HideCountdown = 0

    self.ManualMode = false -- in manual mode the lists are controlled independently from the capacitive status
    self.Enabled = true
end

------------------------------------------------------------------------------------------------------------------------
-- 'Public' Interface
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:getFocusCap()
	return self.CachedFocusCap
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:reset()

    self.ManualMode = false
    self.CachedFocusCap = nil
    self.HideCountdown = 0
    self:setVisible(false)

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:setManualMode(Mode)

    self.ManualMode = Mode
end

------------------------------------------------------------------------------------------------------------------------
-- if not in manual mode, is set automatically on a timer from CapacitiveHelper state
function CapacitiveOverlayBase:setFocusCap(FocusCap)

    self.CachedFocusCap = FocusCap

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:isInManualMode()

    return self.ManualMode
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:setEnabled(Enabled)

    self.Enabled = Enabled

    -- make visible if enabling and should be visible
    if Enabled and self.CachedFocusCap and self:isCapEnabled(self.CachedFocusCap) then
        self:setVisible(true)
        self.HideCountdown = 0

    -- hide if disabling yet visible
    elseif not Enabled and self:isVisible() then
        self:setVisible(false)
        self.HideCountdown = 0
    end
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:onTimer()

    if self.ManualMode or not self.Enabled then
        return
    end

    local FocusCap = CapacitiveHelper.getFocusCap(function (Index) return Index and self:isCapEnabled(Index) end)
    local IsCachedFocusCapEnabled = self.CachedFocusCap and self:isCapEnabled(self.CachedFocusCap)

    -- show (Cap is touched and is different from cached one)
    if FocusCap and FocusCap ~= self.CachedFocusCap then
        self.CachedFocusCap = FocusCap

        self:setVisible(true)
        self.HideCountdown = 0

    -- hide straight away (Cap was touched but is not valid anymore)
    elseif self.CachedFocusCap and not IsCachedFocusCapEnabled then

        self:setVisible(false)
        self.HideCountdown = 0

    -- list persists after release... (valid Cap was touched but is not anymore)
    elseif self.HideCountdown == 0 and self.CachedFocusCap and FocusCap == nil and IsCachedFocusCapEnabled then

        self.HideCountdown = 20

    -- ...and hides after some time (timer is on)
    elseif self.HideCountdown > 0 then
        self.HideCountdown = self.HideCountdown - 1

        if self.HideCountdown == 0 or self:isCapEnabled(self.CachedFocusCap) == nil then

            self.CachedFocusCap = nil
            self:setVisible(false)
            return

        -- user touched the encoder again during countdown: reset
        elseif FocusCap and FocusCap == self.CachedFocusCap then
            self.HideCountdown = 0
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
-- 'Virtual' Functions
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:setVisible(Show)
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayBase:isCapEnabled(Cap)
    return false
end

