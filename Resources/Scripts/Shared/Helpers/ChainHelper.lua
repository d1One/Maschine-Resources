require "Scripts/Shared/Helpers/ResourceHelper"

------------------------------------------------------------------------------------------------------------------------

ChainHelper = {}

------------------------------------------------------------------------------------------------------------------------

function ChainHelper.getShortName(Slot, Name, OverridePrefix)

    if Slot then
        local Locator = Slot:getResourceLocator(Name)
        return OverridePrefix and ResourceHelper.getShortNameWithPrefix(Locator, Name, OverridePrefix)
                              or  ResourceHelper.getShortName(Locator, Name)
    end

    return Name

end

