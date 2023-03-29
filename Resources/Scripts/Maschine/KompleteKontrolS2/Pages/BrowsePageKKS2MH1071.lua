require "Scripts/Maschine/KompleteKontrolS2/Pages/BrowsePageKKS2"
require "Scripts/Maschine/Shared/Components/Browser/ProductItemCustomizationsMPlus"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageKKS2MH1071 = class( 'BrowsePageKKS2MH1071', BrowsePageKKS2 )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2MH1071:__init(Controller, SamplingPage)

    BrowsePageKKS2.__init(self, Controller, SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2MH1071:getProductDisplayName(VendorizedName)

    return ProductItemCustomizationsMPlus.getProductDisplayName(VendorizedName)

end

------------------------------------------------------------------------------------------------------------------------

