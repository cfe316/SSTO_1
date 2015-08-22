// Ship configuration info.
set tr to R(0,0,-90). //Make craft fly upright. Perhaps set to R(0,0,0) if you're Eugene.

set KSCLng to -75.
set TargetLng to KSCLng.
set BurnLng to 180 + TargetLng + (98.75 + KSCLng). 
set prepLngAmount to 4. // amount of longitude needed to maneuver ship from prograde to retrograde.
set warpStopLng to BurnLng - prepLngAmount. // last place to stop warping at.
set windowLngAmount to 5. // window of longitude to stop warping in.

// assume current orbit is 100x100km.
set DPeri to 45000. // m. Desired periapsis.

set g to KERBIN:MU / KERBIN:RADIUS^2.
set mu to KERBIN:MU.

function burnTimeNeeded {
	set Da to (SHIP:APOAPSIS + DPeri + 2 * KERBIN:RADIUS)/2. 
	set CV to SHIP:VELOCITY:ORBIT:MAG. // current velocity.
	set CR to SHIP:ALTITUDE + KERBIN:RADIUS. // current radius.
	set DV to SQRT(2 * mu *(1/CR - 1/(2*Da))). // desired velocity. not Delta V.
	set deltaV to CV - DV.
	set nukeThrust to 60.
	set IM to SHIP:MASS. // initial mass.
	set Acc to nukeThrust / IM. // acceleration.
	set timeNeeded to deltaV/Acc.
	RETURN timeNeeded.
}.

function timeAtBurnCenter {
	set v to SHIP:VELOCITY:ORBIT:MAG.
	set rad to SHIP:ALTITUDE + KERBIN:RADIUS.
	set lngPerSec to v * 360 / (2 * constant():PI * rad).
	set lng to SHIP:GEOPOSITION:LNG.
	set DeltaLongitude to BurnLng - lng.
	set timeTill to DeltaLongitude / lngPerSec.
	return TIME + timeTill.
}.

function antennaStow {
	SET topAntenna to SHIP:PARTSTAGGED("topAntenna")[0].
	set mod to topAntenna:GETMODULE("ModuleRTAntenna").
	if mod:GETFIELD("status") = "Operational" {
		mod:DOEVENT("deactivate").
	}
}.

function antennaOn {
	SET topAntenna to SHIP:PARTSTAGGED("topAntenna")[0].
	set mod to topAntenna:GETMODULE("ModuleRTAntenna").
	if mod:GETFIELD("status") = "Off" {
		mod:DOEVENT("activate").
	}
}.

function nukeOn {
	set nukes to SHIP:PARTSNAMED("nuclearEngine").
	for part in nukes {
		set mod to part:GETMODULE("ModuleEngines").
		if mod:GETFIELD("status") = "Off" {
			mod:DOACTION("activate engine", True).
		}
	}
}.

function nukeOff{
	set nukes to SHIP:PARTSNAMED("nuclearEngine").
	for part in nukes {
		set mod to part:GETMODULE("ModuleEngines").
		if mod:GETFIELD("status") = "Nominal" {
			mod:DOEVENT("shutdown engine").
		}
	}
}.

function jetsOff {
	set jets to SHIP:PARTSNAMED("turboFanEngine").
	for part in jets {
		set mod to part:GETMODULE("ModuleEnginesFX").
		mod:DOEVENT("shutdown engine").
	}
}.

function baysClosed {
	set bays to SHIP:PARTSNAMED("ServiceBay.125").
	for part in bays {
		set mod to part:GETMODULE("ModuleAnimateGeneric").
		set event to mod:ALLEVENTS[0].
		if event = "(callable) close, is KSPEVENT" {
			mod:DOEVENT("close").
		}
	}
}.

function openIntakes {
	set rams to SHIP:PARTSNAMED("ramAirIntake").
	for part in rams {
		set mod to part:GETMODULE("ModuleResourceIntake").
		if mod:GETFIELD("status") = "Closed" {
			print "Opening intake!".
			mod:DOEVENT("open intake").
		}
	}
}.

function airControlsOff {
	set winglets to SHIP:PARTSNAMED("winglet3").
	for part in winglets {
		set mod to part:GETMODULE("ModuleControlSurface").
		mod:SETFIELD("pitch",True).
		mod:SETFIELD("yaw",True).
		mod:SETFIELD("roll",True).
	}

	set canards to SHIP:PARTSNAMED("R8winglet").
	for part in canards {
		set mod to part:GETMODULE("ModuleControlSurface").
		mod:SETFIELD("pitch",True).
		mod:SETFIELD("yaw",True).
		mod:SETFIELD("roll",True).
	}
}. 

function prepBurn {
	nukeOn().
	airControlsOff().
}.

function prepAtmo {
	openIntakes().
	nukeOff().
	antennaStow().
	baysClosed().
}.

function popChutes {
	set parach to SHIP:PARTSNAMED("parachuteRadial").
	for part in parach {
		set mod to part:GETMODULE("ModuleParachute").
		mod:DOEVENT("deploy chute").
	}
}.

function prepLand{
	gear on.
	popChutes().
}.

// main script begin.
// Start the script in a known configuration.
clearscreen.
SAS off.
RCS off.
lock throttle to 0. // Throttle goes from 0.0 to 1.0
gear off.
set mode to 1.
set TVAL to 0.
// This the the main prorgram loop. It runs until the program ends.
until mode = 0 {

	if mode = 1 { // warp until craft is in the right spot.
		SET WARPMODE TO "RAILS".
		SET WARP TO 4.
		set lng to SHIP:GEOPOSITION:LNG.
		if lng < warpStopLng AND lng > warpStopLng - windowLngAmount {
			SET WARP TO 0.
			set mode to mode + 1.
		}
	}

	else if mode = 2 { // batten down the hatches!
		prepBurn(). // activate nuke, close bays, turn off air controls.
		set bCT to timeAtBurnCenter().
		set bTN to burnTimeNeeded().
		set burnStartTime to bCT - bTN/2.
		clearscreen.
		set mode to mode + 1.
	}

	else if mode = 3 {
		lock steering to heading(-90,0) + tr. //set to retrograde. 
		if TIME - burnStartTime > 0 {
			set mode to mode + 1.
		}
	}

	else if mode = 4 {
		set TVAL to 1.
		lock steering to heading(-90,0) + tr.
		if SHIP:PERIAPSIS < DPeri {
			set mode to mode + 1.
		}
	}

	else if mode = 5 {
		unlock steering.
		SAS on.
		set SASMODE to "RADIALIN".
		set TVAL to 0.
		SET WARP TO 4.
		if SHIP:ALTITUDE < 72500 {
			SET WARP TO 0.
			set mode to mode + 1.
		}
	}

	else if mode = 6 {
		wait 1.
		prepAtmo().
		wait 1.
		set mode to mode + 1.
	}

	else if mode = 7 {
		if SHIP:ALTITUDE < 69500 {
			SET WARPMODE to "PHYSICS".
			SET WARP to 3.
			SAS off.
			set mode to mode + 1.
		}
	}

	else if mode = 8 {
		if ALT:RADAR < 1500 {
			SET WARP to 0.
			prepLand().
			SAS ON.
			SET SASMODE to "RETROGRADE".
			set mode to mode + 1.
			print "ALT:   " + round(ALT:RADAR) + "       "at (5,6).
		}
	}

	else if mode = 9 {
		if ALT:RADAR < 1000 {
			antennaOn().
			SAS off.
			set mode to mode + 1.
		}
	}

	else if mode = 10 {
		if ALT:RADAR < 220 {
			set v to SHIP:VELOCITY:SURFACE:MAG.
			set VDes to 5.
			if ALT:RADAR < 30 {
				set VDes to 2.
			}
			if v > VDes + 0 {
				set TVAL to MIN(TVAL + 0.05, 0.45).
				wait 0.3.
			} else if v < VDes {
				set TVAL to MAX(TVAL - 0.01, 0).
				wait 0.3.
			}
			set stat to SHIP:STATUS.
			if stat = "LANDED" or stat = "SPLASHED" {
				set mode to 20.
				jetsOff().
				SAS on.
				set SASMODE to "STABILITYASSIST".
			}
		}
	}

	//end program
	else if mode = 20 {
		set TVAL to 0.
		unlock steering.
		set mode to 0.
	}

	lock throttle to TVAL.

	print "MODE:    " + mode + "      " at (5,4).
	print "LNG:     " + round(lng*100)/100 + "     " at (5,5).
}
