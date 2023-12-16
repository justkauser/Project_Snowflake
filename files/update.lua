-- files/update.lua
local snow = require("files.libs.snowflake")
local update = {}

function update.update(dt,data)
    snow.update(dt,data)
end
    
function update.GUI(dt,ui,data)
    if ui.button('Let it snow!') then
        data.run = true       
    end
    data.particle = ui.slider('##particlecount',  data.particle, 0, 5000, 'Particle: %.0f%')   
end  
return update