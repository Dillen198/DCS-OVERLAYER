-- DCS World Export Script - Using correct DCS API functions
-- Replace your entire Export.lua with this
-- 1.2

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
        -- Create Temp directory if it doesn't exist
        lfs.mkdir(lfs.writedir().."Temp")
        
        dataFile = io.open(lfs.writedir().."Temp/dcs_overlay_data.json", "w")
        if dataFile then
            log.write('DCS-OVERLAY', log.INFO, 'Overlay data file initialized at: ' .. lfs.writedir().."Temp/dcs_overlay_data.json")
        else
            log.write('DCS-OVERLAY', log.ERROR, 'Failed to create data file')
        end
    end)
end

function LuaExportBeforeNextFrame()
    -- Empty - no other scripts
end

function LuaExportAfterNextFrame()
    debugCounter = debugCounter + 1
    
    -- Log every 100 calls to show the function is running
    if debugCounter % 100 == 0 then
        log.write('DCS-OVERLAY', log.INFO, 'LuaExportAfterNextFrame() running (call #' .. debugCounter .. ')')
    end
    
    -- Export overlay data
    local success, error_msg = pcall(function()
        local now = LoGetModelTime()
        
        -- Debug: Log time info
        if debugCounter % 500 == 0 then
            log.write('DCS-OVERLAY', log.INFO, 'Time check - now: ' .. tostring(now) .. ', nextUpdate: ' .. tostring(nextUpdateTime))
        end
        
        if dataFile and now and nextUpdateTime and now > nextUpdateTime then
            nextUpdateTime = now + UPDATE_INTERVAL
            
            log.write('DCS-OVERLAY', log.INFO, 'Attempting to get aircraft data...')
            
            -- Get aircraft data
            local selfData = LoGetSelfData()
            if selfData then
                log.write('DCS-OVERLAY', log.INFO, 'Aircraft found: ' .. tostring(selfData.Name))
                
                log.write('DCS-OVERLAY', log.INFO, 'Getting payload info...')
                local payloadInfo = LoGetPayloadInfo()
                
                log.write('DCS-OVERLAY', log.INFO, 'Getting fuel info...')
                -- Use correct DCS API function for fuel
                local engineInfo = LoGetEngineInfo()
                
                log.write('DCS-OVERLAY', log.INFO, 'Creating data structure...')
                -- Create data packet
                local data = {
                    timestamp = now,
                    aircraft = selfData.Name,
                    fuel = {
                        internal = engineInfo and engineInfo.fuel_internal or 0,
                        external = engineInfo and engineInfo.fuel_external or 0,
                        total = engineInfo and engineInfo.fuel_total or 0
                    },
                    weapons = {}
                }
                
                log.write('DCS-OVERLAY', log.INFO, 'Extracting weapons data...')
                -- Extract weapons data
                local weaponCount = 0
                if payloadInfo and payloadInfo.Stations then
                    for stationId, station in pairs(payloadInfo.Stations) do
                        if station.weapon then
                            weaponCount = weaponCount + 1
                            table.insert(data.weapons, {
                                station = stationId,
                                name = station.weapon.displayName,
                                count = station.weapon.count or 1,
                                category = station.weapon.level1 or "Unknown"
                            })
                        end
                    end
                end
                
                log.write('DCS-OVERLAY', log.INFO, 'Creating JSON...')
                -- Write JSON data to file
                local json = encodeJSON(data)
                log.write('DCS-OVERLAY', log.INFO, 'JSON created, length: ' .. string.len(json))
                
                -- Debug: Log the actual JSON content (first 200 chars)
                log.write('DCS-OVERLAY', log.INFO, 'JSON preview: ' .. string.sub(json, 1, 200))
                
                log.write('DCS-OVERLAY', log.INFO, 'Writing to file...')
                dataFile:seek("set", 0)  -- Go to beginning of file
                local writeResult = dataFile:write(json)
                dataFile:flush()
                
                log.write('DCS-OVERLAY', log.INFO, 'File write result: ' .. tostring(writeResult))
                
                -- Verify file size
                local fileSize = dataFile:seek("end")
                dataFile:seek("set", 0)
                log.write('DCS-OVERLAY', log.INFO, 'File size after write: ' .. tostring(fileSize) .. ' bytes')
                
                log.write('DCS-OVERLAY', log.INFO, 'SUCCESS: Data exported for ' .. selfData.Name .. ' with ' .. weaponCount .. ' weapons')
            else
                log.write('DCS-OVERLAY', log.INFO, 'No aircraft data - player not in cockpit or aircraft not loaded')
                
                -- Write empty state so we know the script is working
                local emptyData = {
                    timestamp = now,
                    aircraft = "NO_AIRCRAFT",
                    fuel = { internal = 0, external = 0, total = 0 },
                    weapons = {}
                }
                local json = encodeJSON(emptyData)
                dataFile:seek("set", 0)
                dataFile:write(json)
                dataFile:flush()
                
                log.write('DCS-OVERLAY', log.INFO, 'Wrote empty state to file')
            end
        else
            -- Debug why we're not updating
            if not dataFile then
                log.write('DCS-OVERLAY', log.ERROR, 'dataFile is nil')
            elseif not now then
                log.write('DCS-OVERLAY', log.ERROR, 'LoGetModelTime() returned nil')
            elseif not (now > nextUpdateTime) then
                -- This is normal, don't log every time
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
            log.write('DCS-OVERLAY', log.INFO, 'Overlay data file closed')
        end
    end)
end

-- Simple JSON encoder
function encodeJSON(obj)
    if type(obj) == "table" then
        local items = {}
        local isArray = true
        
        -- Check if it's an array
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

-- Test at startup
log.write('DCS-OVERLAY', log.INFO, 'Corrected Export.lua loaded - using LoGetEngineInfo for fuel')