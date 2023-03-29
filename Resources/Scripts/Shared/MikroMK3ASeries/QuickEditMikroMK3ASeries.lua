local class = require 'Scripts/Shared/Helpers/classy'
QuickEditMikroMK3ASeries = class( 'QuickEditMikroMK3ASeries' )

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3ASeries.getSongTempoString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Parameter = Song and Song:getTempoParameter()
    return Parameter and Parameter:getAsString(Parameter:getValue()).." BPM" or "N/A"

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMikroMK3ASeries.incrementSongTempo(Inc, IsFineIncrement)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Parameter = Song and Song:getTempoParameter()
    if Parameter then
        local IsUndoable = true
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, Parameter, Inc, IsFineIncrement, IsUndoable)
    end

end

