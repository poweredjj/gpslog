-- GPS Logger for EdgeTX (RadioMaster) by Marcin Smidowicz
-- Logs GPS coordinates for each arm-disarm cycle and saves them as a GPX file

-- INSTALLATION AND USAGE
-- 1. Copy gpslog.lua to /SCRIPTS/TELEMETRY.
-- 2. In model setup / display select screen -> script -> gpslog.
-- 3. GPS logging will be automatic during arm - disarm period.
-- 4. if GPS fix is acquired, GPX logs will be saved to /LOGS.

-- Tested with RadioMaster Pocket, BetaFlight 4.5.1 and M100 GPS.
-- You can freely use and modify this script.

local mid = LCD_W / 2  -- Center alignment for LCD display
local gpsLatLonId
local gpsAltId
local chArmedId
local armed
local arm_time = 0 -- timestamp when armed
local last_waypoint_add_time = 0
local waypoints_recorded = 0
local latitude, longitude = 0.0, 0.0
local altitude = 0.0
local gpx_path = ""

-- Initialization function
local function init_func()
    gpsLatLonId = getFieldInfo("GPS") and getFieldInfo("GPS").id or nil;
    gpsAltId  = getFieldInfo("Alt") and getFieldInfo("Alt").id or nil;
	chArmedId = getFieldInfo('ch5').id	
end


local function write_gps_file_header()
	local dt = getDateTime()		
	local timestamp = string.format(
	"%d-%02d-%02dT%02d:%02d:%02d",
	tonumber(dt.year), tonumber(dt.mon ), tonumber(dt.day),
	tonumber(dt.hour), tonumber(dt.min ), tonumber(dt.sec))
		
	io.write(log_file, "<?xml version='1.0' encoding='UTF-8'?>\n")
	io.write(log_file, "<gpx version='1.1' creator='EdgeTX Lua Script' xmlns='http://www.topografix.com/GPX/1/1'>\n")
		
	io.write(log_file, string.format("<metadata><time>%s</time></metadata>\n", timestamp))
	io.write(log_file, string.format("<trk><name>Flight Log</name><trkseg>\n", timestamp))
end

local function write_gps_file_footer()
	io.write(log_file, "</trkseg></trk>\n")
	io.write(log_file, "</gpx>")
end

local function bg_func()
	armed = getValue(chArmedId) > 0
	
	if log_file == nil and armed then
		arm_time = getTime()
		
		local dt = getDateTime()		
		local timestamp = string.format(
		"%d-%02d-%02d_%02d_%02d_%02d",
		tonumber(dt.year), tonumber(dt.mon ), tonumber(dt.day),
		tonumber(dt.hour), tonumber(dt.min ), tonumber(dt.sec))
		
		gpx_path = string.format("/LOGS/gps_log_%s.gpx", timestamp)		
		
		log_file = io.open(gpx_path, "a")	
		waypoints_recorded = 0

		write_gps_file_header()
	end	
		
	if not armed and log_file ~= nil then
		if waypoints_recorded < 2 then -- no point in storing empty logs
			io.close(log_file)
			del(gpx_path)	
		else
			write_gps_file_footer()
			io.close(log_file)
		end
		
		log_file = nil
		gpx_path = ""
		waypoints_recorded = 0	
	end
	
	local gpsLatLon = getValue(gpsLatLonId)
	local altitude_new = getValue(gpsAltId)
	
	local elapsed_time = (getTime() - arm_time) / 20 -- units smaller than seconds
		
	if armed
	and elapsed_time > last_waypoint_add_time + 1
	and gpsLatLon ~= 0
	and (gpsLatLon.lat ~= latitude or gpsLatLon.lon ~= longitude or altitude_new ~= altitude) then	
		latitude = gpsLatLon.lat
		longitude = gpsLatLon.lon
		altitude = altitude_new
	
		local dt = getDateTime()
		local timestamp = string.format(
		"%d-%02d-%02dT%02d:%02d:%02d",
		tonumber(dt.year), tonumber(dt.mon), tonumber(dt.day),
		tonumber(dt.hour), tonumber(dt.min), tonumber(dt.sec))
					
		io.write(log_file, string.format(
		"<trkpt lat='%f' lon='%f'><ele>%f</ele><time>%s</time></trkpt>\n", 
		latitude, longitude, altitude, timestamp))
		
		last_waypoint_add_time = elapsed_time
		waypoints_recorded = waypoints_recorded + 1
	end	
end


local function run_func()
    lcd.clear()
	
    if armed then
        local elapsed_time = (getTime() - arm_time) / 100  -- seconds
		lcd.drawText(5, 00, string.format("REC (waypoints: %d)", waypoints_recorded), 0)
		lcd.drawText(5, 10, string.format("Time: %d sec", elapsed_time), 0)
    else
        lcd.drawText(5, 00, "IDLE", 0)
    end	
	lcd.drawText(5, 20, "GPS: " .. tostring(latitude) .. ", " .. tostring(longitude), 0)
	lcd.drawText(5, 30, string.format("altitude %f", altitude), 0)
    
    return 0
end

return {run=run_func, init=init_func, background=bg_func}
