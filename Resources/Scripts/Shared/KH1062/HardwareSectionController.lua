local class = require 'Scripts/Shared/Helpers/classy'
HardwareSectionController = class( 'HardwareSectionController' )

------------------------------------------------------------------------------------------------------------------------

function HardwareSectionController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function HardwareSectionController:configureERPs(EncoderMode)

    NHLController:setEncoderMode(EncoderMode)

end

------------------------------------------------------------------------------------------------------------------------

function HardwareSectionController:acquireSectionControl(Section, Acquire)

    if Acquire then
        NI.HW.acquireSectionControl(App, Section)
    else
        NI.HW.releaseSectionControl(App, Section)
    end

end

------------------------------------------------------------------------------------------------------------------------

function HardwareSectionController:getCurrentOctave()

    return NI.HW.getCurrentOctave(App)

end
