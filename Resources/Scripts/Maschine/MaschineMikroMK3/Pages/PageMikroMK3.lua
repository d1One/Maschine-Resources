------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/ScreenMikroMK3"
require "Scripts/Shared/Helpers/PadModeHelper"

local class = require 'Scripts/Shared/Helpers/classy'
PageMikroMK3 = class( 'PageMikroMK3' )

------------------------------------------------------------------------------------------------------------------------

function PageMikroMK3:__init(Name, Controller)

    self.Name = Name
    self.Controller = Controller

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------
-- @remarks: override this to create a custom screen

function PageMikroMK3:setupScreen()

    self.Screen = ScreenMikroMK3(self)

end

------------------------------------------------------------------------------------------------------------------------

function PageMikroMK3:onShow(Show)

    if Show then
        self.Screen:onPageShow()
        self:updateScreen()
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- on TransactionObject changed; calling something from here that creates a TM::Transaction will fail

function PageMikroMK3:onStateFlagsChanged()

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function PageMikroMK3:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------
