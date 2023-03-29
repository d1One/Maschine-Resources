require "Scripts/Shared/Components/IntervalMap"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadMapper = class( 'PadMapper' )

------------------------------------------------------------------------------------------------------------------------

function PadMapper:__init()

    self.Map = IntervalMap(nil)

end

------------------------------------------------------------------------------------------------------------------------
-- PadEnd is optional and might hold the Handlers
function PadMapper:map(PadStart, PadEnd, Handlers)

    if type(PadEnd) == "table" then
        Handlers = PadEnd
        PadEnd = PadStart
    end

    self.Map:assign(PadStart, PadEnd + 1, Handlers)

end

------------------------------------------------------------------------------------------------------------------------

function PadMapper:find(PadIndex, Context)

    local Handlers = self.Map:at(PadIndex)
    if not Handlers then
        return
    end

    for _, Handler in pairs(Handlers) do
        if not Handler.When or Handler.When(Context) then
            return Handler
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
