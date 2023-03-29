require "Scripts/Shared/KH1062/SwitchEventTable"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SwitchHandler = class( 'SwitchHandler' )

function SwitchHandler:__init(ShiftButtonIndex)

    self.ShiftSwitchID = ShiftButtonIndex
    self.SwitchPressed = {}
    self.GlobalSwitchEventTable = SwitchEventTable()
    self.PageSwitchEventTable = nil

end

------------------------------------------------------------------------------------------------------------------------

function SwitchHandler:onSwitchEvent(SwitchID, Pressed)

    self.SwitchPressed[SwitchID] = Pressed

    local IsShiftPressed = self:isShiftPressed()

    if self.PageSwitchEventTable then
        if self.PageSwitchEventTable:handleSwitchEvent(IsShiftPressed, SwitchID, Pressed) then
            return
        end
    end

    self.GlobalSwitchEventTable:handleSwitchEvent(IsShiftPressed, SwitchID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SwitchHandler:setPageSwitchEventTable(PageTable)

    self.PageSwitchEventTable = PageTable

end

------------------------------------------------------------------------------------------------------------------------

function SwitchHandler:getGlobalSwitchEventTable()

    return self.GlobalSwitchEventTable

end

------------------------------------------------------------------------------------------------------------------------

function SwitchHandler:isShiftPressed()

    return self.SwitchPressed[self.ShiftSwitchID] == true

end
