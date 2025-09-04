-- DCS World Export Script - Using correct DCS API from wiki
-- Replace your entire Export.lua with this

local lfs = require('lfs')

-- Configuration for DCS Overlay  
local UPDATE_INTERVAL = 0.1 -- seconds
local nextUpdateTime = 0
local dataFile = nil
local debugCounter = 0

function LuaExportStart()
    log.write('DCS-OVERLAY', log.INFO, 'LuaExportStart() called')
    
    -- Initialize data file for overlay
    pcall(function()
        lfs.mkdir(lfs.writedir().."Temp")
        dataFile = io.open(lfs.writedir().."Temp/dcs_overlay_data.json", "w")
        if dataFile then
            log.write('DCS-OVERLAY', log.INFO, 'Overlay data file initialized')
        else
            log.write('DCS-OVERLAY', log.ERROR, 'Failed to create data file')
        end
    end)
end

function LuaExportBeforeNextFrame()
    -- Empty
end

function LuaExportAfterNextFrame()
    debugCounter = debugCounter + 1
    
    if debugCounter % 100 == 0 then
        log.write('DCS-OVERLAY', log.INFO, 'LuaExportAfterNextFrame() running (call #' .. debugCounter .. ')')
    end
    
    local success, error_msg = pcall(function()
        local now = LoGetModelTime()
        
        if dataFile and now and nextUpdateTime and now > nextUpdateTime then
            nextUpdateTime = now + UPDATE_INTERVAL
            
            -- Get aircraft data using correct DCS API
            local selfData = LoGetSelfData()
            if selfData then
                log.write('DCS-OVERLAY', log.INFO, 'Aircraft found: ' .. tostring(selfData.Name))
                
                -- Get payload info
                local payloadInfo = LoGetPayloadInfo()
                
                -- Get fuel data from engine info (correct API)
                local engineInfo = LoGetEngineInfo()
                local fuelData = {
                    internal = 0,
                    external = 0,
                    total = 0
                }
                
                if engineInfo then
                    fuelData.internal = engineInfo.fuel_internal or 0
                    fuelData.external = engineInfo.fuel_external or 0
                    fuelData.total = (engineInfo.fuel_internal or 0) + (engineInfo.fuel_external or 0)
                    log.write('DCS-OVERLAY', log.INFO, 'Fuel data - Internal: ' .. fuelData.internal .. ', External: ' .. fuelData.external .. ', Total: ' .. fuelData.total)
                end
                
                -- Create data packet
                local data = {
                    timestamp = now,
                    aircraft = selfData.Name,
                    fuel = fuelData,
                    weapons = {
                        air_to_air = {},
                        air_to_ground = {},
                        other = {}
                    }
                }
                
                -- Extract weapons data with categorization
                local weaponCount = 0
                if payloadInfo and payloadInfo.Stations then
                    for stationId, station in pairs(payloadInfo.Stations) do
                        if station.weapon then
                            weaponCount = weaponCount + 1
                            
                            -- Get weapon name using correct API
                            local weaponName = LoGetNameByType(station.weapon.level1, station.weapon.level2, station.weapon.level3, station.weapon.level4)
                            if not weaponName then
                                weaponName = "Unknown Weapon"
                            end
                            
                            log.write('DCS-OVERLAY', log.INFO, 'Weapon - Station: ' .. stationId .. ', Name: ' .. weaponName .. ', Levels: ' .. station.weapon.level1 .. ',' .. station.weapon.level2 .. ',' .. station.weapon.level3 .. ',' .. station.weapon.level4)
                            
                            -- Categorize weapons based on weapon name patterns (more reliable than level1)
                            local isAirToAir = false
                            local isAirToGround = false
                            
                            -- Air-to-Air weapon patterns
                            if string.find(string.upper(weaponName), "AIM%-120") or 
                               string.find(string.upper(weaponName), "AIM%-9") or
                               string.find(string.upper(weaponName), "AIM%-7") or
                               string.find(string.upper(weaponName), "AIM%-54") or
                               string.find(string.upper(weaponName), "R%-60") or
                               string.find(string.upper(weaponName), "R%-73") or
                               string.find(string.upper(weaponName), "R%-27") or
                               string.find(string.upper(weaponName), "R%-77") or
                               string.find(string.upper(weaponName), "PL%-12") or
                               string.find(string.upper(weaponName), "PL%-15") or
                               string.find(string.upper(weaponName), "PL%-8") or
                               string.find(string.upper(weaponName), "PL%-5") or
                               string.find(string.upper(weaponName), "SD%-10") or
                               string.find(string.upper(weaponName), "MICA") or
                               string.find(string.upper(weaponName), "MAGIC") or
                               string.find(string.upper(weaponName), "METEOR") or
                               string.find(string.upper(weaponName), "CANNON") then
                                isAirToAir = true
                            -- Air-to-Ground weapon patterns  
                            elseif string.find(string.upper(weaponName), "MK%-") or
                                   string.find(string.upper(weaponName), "GBU%-") or
                                   string.find(string.upper(weaponName), "AGM%-") or
                                   string.find(string.upper(weaponName), "CBU%-") or
                                   string.find(string.upper(weaponName), "MAVERICK") or
                                   string.find(string.upper(weaponName), "HELLFIRE") or
                                   string.find(string.upper(weaponName), "HARM") or
                                   string.find(string.upper(weaponName), "JDAM") or
                                   string.find(string.upper(weaponName), "PAVEWAY") then
                                isAirToGround = true
                            -- Pods and support equipment
                            elseif string.find(string.upper(weaponName), "POD") or
                                   string.find(string.upper(weaponName), "LITENING") or
                                   string.find(string.upper(weaponName), "SNIPER") or
                                   string.find(string.upper(weaponName), "HTS") or
                                   string.find(string.upper(weaponName), "ALQ") or
                                   string.find(string.upper(weaponName), "TANK") then
                                -- Skip pods and support equipment
                            else
                                -- Unknown weapons go to other category
                            end
                            
                            local weapon = {
                                station = stationId,
                                name = weaponName,
                                count = station.count or 1,
                                category = station.weapon.level1 or 0
                            }
                            
                            if isAirToAir then
                                table.insert(data.weapons.air_to_air, weapon)
                            elseif isAirToGround then
                                table.insert(data.weapons.air_to_ground, weapon)
                            else
                                table.insert(data.weapons.other, weapon)
                            end
                        end
                    end
                end
                
                -- Add cannon info if available
                if payloadInfo and payloadInfo.Cannon then
                    table.insert(data.weapons.air_to_air, {
                        station = 0,
                        name = "Cannon",
                        count = payloadInfo.Cannon.shells or 0,
                        category = "Gun"
                    })
                end
                
                -- Write JSON data to file
                local json = encodeJSON(data)
                
                dataFile:close()
                dataFile = io.open(lfs.writedir().."Temp/dcs_overlay_data.json", "w")
                
                if dataFile then
                    dataFile:write(json)
                    dataFile:flush()
                    log.write('DCS-OVERLAY', log.INFO, 'SUCCESS: Data exported for ' .. selfData.Name .. ' with ' .. weaponCount .. ' weapons')
                end
            end
        end
    end)
    
    if not success then
        log.write('DCS-OVERLAY', log.ERROR, 'Error in export function: ' .. tostring(error_msg))
    end
end

function LuaExportActivityNextEvent(t)
    return t + 0.01
end

function LuaExportStop()
    log.write('DCS-OVERLAY', log.INFO, 'LuaExportStop() called')
    pcall(function()
        if dataFile then
            dataFile:close()
        end
    end)
end

-- Simple JSON encoder
function encodeJSON(obj)
    if type(obj) == "table" then
        local items = {}
        local isArray = true
        local count = 0
        
        for k, v in pairs(obj) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                isArray = false
                break
            end
        end
        
        if isArray then
            for i, v in ipairs(obj) do
                table.insert(items, encodeJSON(v))
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            for k, v in pairs(obj) do
                table.insert(items, '"' .. tostring(k) .. '":' .. encodeJSON(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    elseif type(obj) == "string" then
        return '"' .. obj:gsub('"', '\\"') .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    else
        return "null"
    end
end

log.write('DCS-OVERLAY', log.INFO, 'Corrected Export.lua loaded with proper DCS API')