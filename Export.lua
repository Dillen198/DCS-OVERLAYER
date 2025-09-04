-- DCS World Export Script with RWR Support
-- Using correct DCS API from wiki documentation

local lfs = require('lfs')

-- Configuration for DCS Overlay  
local UPDATE_INTERVAL = 0.1 -- seconds
local nextUpdateTime = 0
local dataFile = nil
local debugCounter = 0

function LuaExportStart()
    log.write('DCS-OVERLAY', log.INFO, 'LuaExportStart() called with RWR support')
    
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
                
                -- Get fuel data from engine info
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
                    log.write('DCS-OVERLAY', log.INFO, 'Fuel: ' .. fuelData.total)
                end
                
                -- Get RWR/TWS data
                local rwrData = {
                    mode = 0,
                    emitters = {}
                }
                
                local twsInfo = LoGetTWSInfo()
                if twsInfo then
                    rwrData.mode = twsInfo.Mode or 0
                    
                    if twsInfo.Emitters then
                        for i, emitter in pairs(twsInfo.Emitters) do
                            -- Process each emitter
                            local threatName = "UNK"
                            
                            -- Try to identify the threat
                            if emitter.Type then
                                local level1 = emitter.Type.level1 or 0
                                local level2 = emitter.Type.level2 or 0
                                local level3 = emitter.Type.level3 or 0
                                local level4 = emitter.Type.level4 or 0
                                
                                -- Try to get name from type
                                threatName = LoGetNameByType(level1, level2, level3, level4) or "UNK"
                                
                                -- Fallback to common threat identifications
                                if threatName == "UNK" then
                                    -- Air Defense systems
                                    if level1 == 16 and level2 == 2 then
                                        if level3 == 7 then threatName = "SA-11"
                                        elseif level3 == 2 then threatName = "SA-6"
                                        elseif level3 == 10 then threatName = "SA-10"
                                        elseif level3 == 12 then threatName = "SA-15"
                                        elseif level3 == 13 then threatName = "SA-19"
                                        end
                                    -- Aircraft
                                    elseif level1 == 1 then
                                        if level2 == 1 then -- Fighter
                                            if level3 == 7 then threatName = "F-16"
                                            elseif level3 == 6 then threatName = "F-15"
                                            elseif level3 == 5 then threatName = "F-18"
                                            elseif level3 == 1 then threatName = "MIG-29"
                                            elseif level3 == 2 then threatName = "SU-27"
                                            end
                                        end
                                    end
                                end
                            end
                            
                            table.insert(rwrData.emitters, {
                                id = emitter.ID or i,
                                name = threatName,
                                power = emitter.Power or 0,
                                azimuth = emitter.Azimuth or 0,
                                priority = emitter.Priority or 0,
                                signal = emitter.SignalType or "scan"
                            })
                            
                            log.write('DCS-OVERLAY', log.INFO, 'RWR Threat: ' .. threatName .. ' Signal: ' .. (emitter.SignalType or "scan"))
                        end
                    end
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
                    },
                    rwr = rwrData
                }
                
                -- Extract weapons data
                local weaponCount = 0
                if payloadInfo and payloadInfo.Stations then
                    for stationId, station in pairs(payloadInfo.Stations) do
                        if station.weapon then
                            weaponCount = weaponCount + 1
                            
                            -- Get weapon name
                            local weaponName = LoGetNameByType(station.weapon.level1, station.weapon.level2, station.weapon.level3, station.weapon.level4)
                            if not weaponName then
                                weaponName = "Unknown Weapon"
                            end
                            
                            -- Categorize weapons
                            local isAirToAir = false
                            local isAirToGround = false
                            
                            -- Air-to-Air patterns
                            if string.find(string.upper(weaponName), "AIM%-120") or 
                               string.find(string.upper(weaponName), "AIM%-9") or
                               string.find(string.upper(weaponName), "AIM%-7") or
                               string.find(string.upper(weaponName), "AIM%-54") or
                               string.find(string.upper(weaponName), "R%-60") or
                               string.find(string.upper(weaponName), "R%-73") or
                               string.find(string.upper(weaponName), "R%-27") or
                               string.find(string.upper(weaponName), "R%-77") or
                               string.find(string.upper(weaponName), "CANNON") then
                                isAirToAir = true
                            -- Air-to-Ground patterns
                            elseif string.find(string.upper(weaponName), "MK%-") or
                                   string.find(string.upper(weaponName), "GBU%-") or
                                   string.find(string.upper(weaponName), "AGM%-") or
                                   string.find(string.upper(weaponName), "CBU%-") then
                                isAirToGround = true
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
                
                -- Add cannon info
                if payloadInfo and payloadInfo.Cannon then
                    table.insert(data.weapons.air_to_air, {
                        station = 0,
                        name = "Cannon",
                        count = payloadInfo.Cannon.shells or 0,
                        category = "Gun"
                    })
                end
                
                -- Write JSON data
                local json = encodeJSON(data)
                
                dataFile:close()
                dataFile = io.open(lfs.writedir().."Temp/dcs_overlay_data.json", "w")
                
                if dataFile then
                    dataFile:write(json)
                    dataFile:flush()
                    log.write('DCS-OVERLAY', log.INFO, 'Data exported with ' .. #rwrData.emitters .. ' RWR threats')
                end
            end
        end
    end)
    
    if not success then
        log.write('DCS-OVERLAY', log.ERROR, 'Error: ' .. tostring(error_msg))
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

-- Enhanced JSON encoder with RWR support
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

log.write('DCS-OVERLAY', log.INFO, 'Export.lua with RWR support loaded')