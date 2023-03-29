
local Model = NHLController:getControllerAcronym()

if Model == "MM1" or Model == "MM2" then

    require "Scripts/Maschine/MaschineMikro/MaschineMikroController"

elseif Model == "M1" or Model == "M2" then

    require "Scripts/Maschine/Maschine/MaschineController"

elseif Model == "M3" then

    require "Scripts/Maschine/MaschineMK3/MaschineControllerMK3"

elseif Model == "MH1071" then

    require "Scripts/Maschine/MaschineMH1071/MaschineControllerMH1071"

elseif Model == "MS1" then

    require "Scripts/Maschine/MaschineStudio/MaschineStudioController"

elseif Model == "KK25" or Model == "KK49" or Model == "KK61" or Model == "KK88" then

    require "Scripts/Maschine/KompleteKontrolS/KompleteKontrol"

elseif Model == "MJ1" then

    require "Scripts/Maschine/Jam/JamControllerMk1"

elseif Model == "KKS2_49" or Model == "KKS2_61" or Model == "KKS2_88" then

    require "Scripts/Maschine/KompleteKontrolS2/KompleteKontrol2MAS"

elseif Model == "KKA" or Model == "KKM" then

    require "Scripts/Maschine/KH1062/KH1062Maschine"

elseif Model == "MM3" then

    require "Scripts/Maschine/MaschineMikroMK3/MaschineMikroMK3"

end
