require "Scripts/Maschine/MaschineMK3/Pages/BrowsePageMK3"
require "Scripts/Maschine/Shared/Components/Browser/ProductItemCustomizationsMPlus"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageMH1071 = class( 'BrowsePageMH1071', BrowsePageMK3 )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMH1071:__init(Controller, SamplingPage)

    BrowsePageMK3.__init(self, Controller, SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMH1071:getProductDisplayName(VendorizedName)

    return ProductItemCustomizationsMPlus.getProductDisplayName(VendorizedName)

end

------------------------------------------------------------------------------------------------------------------------
