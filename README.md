# GPS logger for EdgeTX


## INSTALLATION AND USAGE
1. Copy ```gpslog.lua``` to ```/SCRIPTS/TELEMETRY```.
2. In model setup / display select screen -> script -> gpslog.
3. GPS logging will be automatic during arm - disarm period.
4. If GPS fix is acquired, GPX logs will be saved to ```/LOGS```.

If GPS data logging frequency is too slow (especially if you are using a slower packet rate), go to ExpressLRS configurator app and increase ```telemetry ratio```.

Tested with RadioMaster Pocket, ExpressLRS 3.5.1, BetaFlight 4.5.1 and M100 GPS.

You can freely use and modify this script.


<img align="left" width="300" height="300" src="screenshot.png">
<img align="left" width="300" height="300" src="example_track_preview.jpeg">

