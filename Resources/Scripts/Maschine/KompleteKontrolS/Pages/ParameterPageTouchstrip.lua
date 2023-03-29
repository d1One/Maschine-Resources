------------------------------------------------------------------------------------------------------------------------
-- Page that displays Touchstrip configuration parameters.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"

local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageTouchstrip = class( 'ParameterPageTouchstrip', ParameterPageBase )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ParameterPageTouchstrip:__init(Controller, PageIndex)

    ParameterPageBase.__init(self, Controller)

    self.PageIndex = PageIndex

    self.NumPages = App:getTouchstripConfiguration():getNumPages(0)
    self.PageField = "TS " .. PageIndex + 1 .. "/" .. self.NumPages

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageTouchstrip:updateScreen()

    local TouchstripConfiguration = App:getTouchstripConfiguration()

    for Index = 0, 7 do
        HELPERS.setCachedParameter(App, Index, TouchstripConfiguration:getParameter(0, self.PageIndex, Index))
    end

    -- The following 2 lines setup ParameterPageBase to update LEDs in updateScreen()
    self.NumPages = TouchstripConfiguration:getNumPages(0)
    self:setFocusPage(self.PageIndex + 1)

    ParameterPageBase.updateScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageTouchstrip:onEncoderEvent(EncoderID, Value)
    local Parameter = HELPERS.getCachedParameter(App, EncoderID)
    if Parameter then
        NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Parameter, Value, false, false)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageTouchstrip:onPageButton(Pressed, Next)

    ParameterPageBase.onPageButton(self, Pressed, Next)

    if Pressed and not self.Controller:isShiftPressed() then
        local PageParameter = App:getWorkspace():getKKPerformPageParameter()
        local NewFocus = math.bound(self.PageIndex + (Next and 1 or -1), 0, 1)
        local TouchstripPage = NewFocus == 1 and HW.PAGE_TOUCHSTRIP_MODULATION or HW.PAGE_TOUCHSTRIP_PITCH

        NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, TouchstripPage)
    end

end

------------------------------------------------------------------------------------------------------------------------