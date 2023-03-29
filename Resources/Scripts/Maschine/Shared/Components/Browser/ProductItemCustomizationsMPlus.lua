------------------------------------------------------------------------------------------------------------------------
-- Overrides product image tiles and the product names for browsing on Maschine+
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------


local class = require 'Scripts/Shared/Helpers/classy'
ProductItemCustomizationsMPlus = class( 'ProductItemCustomizationsMPlus' )

------------------------------------------------------------------------------------------------------------------------

function ProductItemCustomizationsMPlus.getProductDisplayName(VendorizedName)

    -- Use the product name, unless we're in USER mode and it's actually a volume UUID
    local ProductName = BrowseHelper.extractProductName(VendorizedName)

    if BrowseHelper.getUserMode() then
        local Alias = NI.UTILS.NativeOSBrowserHelpers.contentPathAliasForUuid(App, ProductName)
        if Alias and Alias ~= "" then
            return Alias
        end
    end

    return ProductName

end

------------------------------------------------------------------------------------------------------------------------
