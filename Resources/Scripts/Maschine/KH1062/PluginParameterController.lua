require "Scripts/Shared/Helpers/MaschineHelper"
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PluginParameterController = class( 'PluginParameterController' )

------------------------------------------------------------------------------------------------------------------------

function PluginParameterController:__init()

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterController:incrementFocusPage()

    MaschineHelper.offsetFocusedSoundSlotParameterPage(true)

end

------------------------------------------------------------------------------------------------------------------------

function PluginParameterController:decrementFocusPage()

    MaschineHelper.offsetFocusedSoundSlotParameterPage(false)

end