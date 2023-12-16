-- libs/snowflake.lua
local rand      = require("files.libs.random").jrand 
local simplex   = require("files.libs.simplex")
local kn5_paths = require("files.libs.kn5_path")
--##########################################################################################################
-- Segment 1: Local Variables

-- Array for snowflake functions
snowflake = {}

-- Flag to indicate the first frame
local is_first_frame = true

-- Root node for snowflake models
local root_node = nil
local root_bs = nil

-- Spawn area parameters for snowflake instances
local spawn_center = {0, 10, 0}
local spawn_width = 20.0
local spawn_height = 20.0
local spawn_length = 20.0

-- Initial camera position
local camera_pos_alt = nil

-- Reference to the car state
local car_state = nil

-- Timer for particle initialization
local start_timer = 0

-- Number of snowflake instances
local num_instances = 0

-- Array for snowflake instances
local snowflake_instances = {}

--##########################################################################################################
-- Segment 2: Local Functions

-- Determines the sign of a number
local function sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end

-- Just a special linear interpolation function
local function jlerp(x)    
    return x >= 1 and 1.3 or
           x >= 0.6 and 1.3 + (x - 1) * 2.5 or
           x >= -1.1 and 0.3 or
           1.3
end

--##########################################################################################################
-- Segment 3: Simplex Noise Precomputation

-- Counter for periodic noise samples
local noise_counter = 0

-- Radius of the circle for noise samples
local CIRCLE_RADIUS = 2.8

-- Total number of samples for noise calculation
local TOTAL_SAMPLES = 2000

-- Table to store precomputed noise samples
local noise_samples = {}

-- Precompute noise samples along a circle
for i = 1, TOTAL_SAMPLES do
    local angle = (i / TOTAL_SAMPLES) * (2 * math.pi)
    local x, y = CIRCLE_RADIUS * math.cos(angle), CIRCLE_RADIUS * math.sin(angle)
    table.insert(noise_samples, simplex.Noise2D(x, y))
end

-- Function to get a periodic noise sample
local function get_periodic_sample(index, offset)
    local adjusted_index = (index + offset - 1) % TOTAL_SAMPLES + 1
    return noise_samples[adjusted_index]
end

--##########################################################################################################
-- Segment 4: Load kn5 snowflake models

-- Function to load KN5 models with consideration for probabilities
function snowflake.loadKN5()
    -- Retrieve the paths and probabilities of available snowflake models       
    -- Initialize variables for probability calculations
    local total_probability = 0
    local rand_value = rand()
    local kn5_paths = kn5_paths()
    -- Calculate the total probability for the available models
    for _, model in ipairs(kn5_paths) do
        total_probability = total_probability + model.probability
    end

    -- Select a random model based on probabilities
    local cumulative_probability = 0
    for _, model in ipairs(kn5_paths) do
        cumulative_probability = cumulative_probability + model.probability
        if rand_value <= cumulative_probability / total_probability then
            -- Load and return the selected KN5 model
            return root_bs:loadKN5(model.path)
        end
    end
end

--##########################################################################################################
-- Segment 5: ❄❄❄❄❄ Snowflake functions ❄❄❄❄❄

-- Function to initialize a snowflake with a dynamic lifespan
function snowflake.initializeSnowflake()
    return {
        position = vec3.new(0, 0, 0),
        kn5 = nil,
        lifespan = 0,
        offset = 0,
        NoiseStrength = 0
    }
end

-- Function to give a new life to a snowflake
function snowflake.newlife(snowflake, data, camera_pos, camera_dir, delta_cam_pos)
    local vec3 = data.vec3
    local kn5 = snowflake.kn5

    -- Set the orientation of the kn5 based on camera direction
    kn5:setOrientation(vec3.new(-camera_dir.z + rand(), 0.0 + rand(), camera_dir.x + rand()), nil)

    -- Generate random coordinates within the specified width, height, and length
    local x = rand(spawn_width, 'h')
    local y = spawn_height + rand(spawn_height)
    local z = rand(spawn_length, 'h')

    -- Set the position of the snowflake
    snowflake.position = vec3.new(x, y - 5.0, z)

    -- Update kn5 position and other attributes
    snowflake.kn5 = kn5
    snowflake.lifespan = y * 1.1
    snowflake.offset = math.floor(rand(TOTAL_SAMPLES))
    snowflake.NoiseStrength = rand(0.8)

    return snowflake
end

-- Function to update the state of a snowflake
function snowflake.updateSnowflake(snowflake, dt, data, camera_pos, camera_dir, delta_cam_pos, rot)
    local vec3 = data.vec3
    local g_speed = jlerp(snowflake.position.y)
    local rel_speed = vec3.new(0, -g_speed, 0)
    local noise = vec3.new(get_periodic_sample(noise_counter, snowflake.offset) * snowflake.NoiseStrength, 0, 0)
    local carspeed = vec3.new(-3 * car_state.localVelocity.x, 0, -1.1 * car_state.localVelocity.z)
    local windVelocity = vec3()
    ac.getWindVelocityTo(windVelocity)
    windVelocity.z = -windVelocity.z
    local windrot = vec3.new(rot.cos * windVelocity.x + rot.sin * windVelocity.z, windVelocity.y-windVelocity:length()*(0.5*get_periodic_sample(math.floor(noise_counter/10), 0)+0.5), -rot.sin * windVelocity.x + rot.cos * windVelocity.z)

    -- Update the snowflake position based on various factors
    snowflake.position = snowflake.position + rel_speed * dt + noise * dt + carspeed * dt + windrot / 4 * dt 
    snowflake.lifespan = snowflake.lifespan + rel_speed.y * dt

    local pos = snowflake.position
    rotpos = vec3.new(rot.cos * pos.x + rot.sin * pos.z, pos.y, -rot.sin * pos.x + rot.cos * pos.z)

    -- Adjust the snowflake position to stay within the specified dimensions
    if math.abs(pos.z) > 0.75 * spawn_length then
        snowflake.position.z = -sign(pos.z) * spawn_length / 2.0
    end

    if math.abs(pos.x) > 0.75 * spawn_width then
        snowflake.position.x = -sign(pos.x) * spawn_width / 2.0
    end

    -- Set kn5 position based on the updated snowflake position
    snowflake.kn5:setPosition(rotpos + camera_pos - (16.5 + 7 * car_state.localVelocity.z / 70) * camera_dir)

    return snowflake
end

-- Function to delete excess snowflakes
function snowflake.deleteSnowflakes(numberOfInstances)
    for i = numberOfInstances + 1, #snowflake_instances do
        if snowflake_instances[i] ~= nil then
            if snowflake_instances[i].kn5 ~= nil then
                snowflake_instances[i].kn5:setPosition(0, -1000, 0)
            end
        end
        snowflake_instances[i] = nil
    end
end

--##########################################################################################################
-- Segment 6: UPDATE Function

-- Updates the state of snowflakes based on the provided data
function snowflake.update(dt, data)
    if data.run then
        start_timer = start_timer + dt
        start_timer = math.min(data.particle, start_timer)
        ac = data.ac    
        local particles = 1000    
        local camera_pos = ac.getCameraPosition()
        local camera_dir = ac.getCameraDirection()
        car_state = ac.getCarState(1)
        num_instances = math.floor(math.min(data.particle, start_timer * 50))
        
        snowflake.deleteSnowflakes(num_instances)
        
        if is_first_frame then
            root_node = ac.findNodes('trackRoot:yes')
            root_bs = root_node:createBoundingSphereNode('snow', 3)
            camera_pos_alt = camera_pos
            is_first_frame = false
        end
        
        local delta_cam_pos = camera_pos_alt - camera_pos
        local rad = math.atan2(-camera_dir.x, -camera_dir.z)
        local rot = {cos=math.cos(rad), sin=math.sin(rad)}
        
        for i = 1, num_instances do
            if snowflake_instances[i] == nil then
                snowflake_instances[i] = snowflake.initializeSnowflake()
            end
            
            if snowflake_instances[i].kn5 == nil then
                snowflake_instances[i].kn5 = snowflake.loadKN5()
                snowflake_instances[i] = snowflake.newlife(snowflake_instances[i], data, camera_pos, camera_dir, delta_cam_pos)
            end
            
            if snowflake_instances[i].lifespan <= 0  then
               snowflake_instances[i] = snowflake.newlife(snowflake_instances[i], data, camera_pos, camera_dir, delta_cam_pos) 
            end
            
            if snowflake_instances[i].lifespan > 0 then
                snowflake_instances[i] = snowflake.updateSnowflake(snowflake_instances[i], dt, data, camera_pos, camera_dir, delta_cam_pos, rot)
            end
            
        end 
        noise_counter = noise_counter + 1
        camera_pos_alt = camera_pos
    end
end

--##########################################################################################################

return snowflake
