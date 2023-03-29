------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ResourceHelper = class( 'ResourceHelper' )

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getVBShortName(Name, Fallback)

    return ResourceHelper.getShortNameWithPrefix(Name, Fallback, "VB")

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getShortName(Name, Fallback)

    local Prefix = ""

    if NI.HW.FEATURE.SCREEN_TYPE_MIKRO then
        Prefix = "MIKRO"
    elseif NI.HW.FEATURE.SCREEN_TYPE_CLASSIC then
        Prefix = "MKII"
    elseif NI.HW.FEATURE.SCREEN_TYPE_STUDIO then
        Prefix = "MST"
    end

    return ResourceHelper.getShortNameWithPrefix(Name, Fallback, Prefix)

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getShortNameWithPrefix(Name, Fallback, Prefix)

    if Prefix == nil or Prefix == "" then
        error ("Prefix not supplied")
    end

    if Name then
        local ShortName = NI.UTILS.getManagedResource("shortname", Name, Prefix.."_shortname", false)
        if ShortName and ShortName ~= "" then
            return ShortName
        end
    end

    return Fallback or Name

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getBrowserIcon(Name)

    if Name then
        return NI.UTILS.getManagedResource("image", Name, "MST_artwork", true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getPluginIcon(Name)

    if Name then
        return NI.UTILS.getManagedResource("image", Name, "MST_plugin", true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getLogo(Name)

    if Name then
        return NI.UTILS.getManagedResource("image", Name, "MST_logo", true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ResourceHelper.getColor(Name)

    if Name then
        local Color = NI.UTILS.getManagedResource("color", Name, "MST_bgcolor", true)
        if Color == "" then
            -- Fallback
            Color = NI.UTILS.getManagedResource("color", Name, "VB_bgcolor", true)
        end
        return Color
    end

end
