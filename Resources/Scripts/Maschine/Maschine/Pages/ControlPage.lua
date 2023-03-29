------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/Maschine/Pages/ControlPageControl"
require "Scripts/Maschine/Maschine/Pages/ControlPageEdit"
require "Scripts/Shared/Helpers/ControlHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPage = class( 'ControlPage', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

ControlPage.CONTROL    = 1
ControlPage.EDIT       = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ControlPage:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "ControlPage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_CONTROL }

    -- since we have to change the whole display, we use multiple sub-pages here
    ForwardPageMaschine.addSubPage(self, ControlPage.CONTROL, ControlPageControl(self, Controller))
    ForwardPageMaschine.addSubPage(self, ControlPage.EDIT, ControlPageEdit(self, Controller))
    ForwardPageMaschine.setDefaultSubPage(self, ControlPage.CONTROL)

end

------------------------------------------------------------------------------------------------------------------------
