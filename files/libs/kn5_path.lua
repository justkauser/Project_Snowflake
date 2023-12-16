-- kn5_path.lua

-- SnowflakeModels_med is a table that holds various snowflake models with associated probabilities.
local SnowflakeModels_med = {
    {
        path = 'files/kn5/snowchunk2dmed8tris.kn5',
        probability = 0.008
    },
    {
        path = 'files/kn5/snowflake2dmed8tris.kn5',
        probability = 0.7
    },
    {
        path = 'files/kn5/snowflake2dsmall8tris.kn5',
        probability = 0.3
    }
}
-- ... Further model palettes can be added in the future ...


-- Function that directly returns kn5 paths based on input parameters.
function get(variant)
    -- If no input parameter is provided, the function returns the kn5 paths from the SnowflakeModels_med table.
    if variant == nil then
        return SnowflakeModels_med
    -- If the input parameter is a number, the function returns the corresponding kn5 paths table.
    elseif type(variant) == "number" then
        local index = math.floor(variant)
        if index == 0 then
            return SnowflakeModels_med
            
--      elseif for further model palettes can be added in the future ...

        else
            return SnowflakeModels_med
        end
    end
end

return get

