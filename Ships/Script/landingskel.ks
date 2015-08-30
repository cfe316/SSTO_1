copy lib from archive.
run lib.
lock SM to S:MASS.
lock ALTI to S:ALTITUDE.
lock APO to S:APOAPSIS.
lock PER to S:PERIAPSIS.
set tr to R(0,0,-90). 
set KSCLng to -75.
set TargetLng to KSCLng.
set BurnLng to 180 + TargetLng + (CorrectionLng + KSCLng). 
set prepLngAmount to 4. 
set warpStopLng to BurnLng - prepLngAmount. 
set windowLngAmount to 5. 
set DPeri to 45*k. 
function prepBurn {
	rokOn().
	airControlsOff().
}.
function prepAtmo {
	rokOff().
	antennaStow().
	baysClosed().
}.
function prepLand{
	openIntakes().
	gear on.
	chutes on.
	descentControlConfig(false).
}.
clearscreen.
SAS off.
RCS off.
lock throttle to 0. 
gear off.
set mode to 1.
set TVAL to 0.
until mode = 0 {
	if mode = 1 { 
		SET WARPMODE TO "RAILS".
		SET WARP TO 4.
		set lng to LONGITUDE.
		if lng < warpStopLng AND lng > warpStopLng - windowLngAmount {
			SET WARP TO 0.
			wait 0.2.
			prepBurn().
			set mode to mode + 1.
		}
	}
	else if mode = 2 { 
		set bCT to timeAtBurnCenter().
		set bTN to burnTimeNeeded().
		set burnStartTime to bCT - bTN/2.
		clearscreen.
		set mode to mode + 1.
	}
	else if mode = 3 {
		lock steering to heading(-90,0) + tr. 
		if TIME - burnStartTime > 0 {
			set mode to mode + 1.
		}
	}
	else if mode = 4 {
		set TVAL to 1.
		lock steering to heading(-90,0) + tr.
		if PER < DPeri {
			set mode to mode + 1.
		}
	}
	else if mode = 5 {
		unlock steering.
		SAS on.
		set SASMODE to "RADIALIN".
		set TVAL to 0.
		SET WARP TO 4.
		if ALTI < 72500 {
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
		if ALTI < 69500 {
			SET WARPMODE to "PHYSICS".
			SET WARP to 3.
			SAS off.
			set mode to mode + 1.
			descentControlConfig(true).
		}
	}
	else if mode = 8 {
		if ALT:RADAR < 2000 {
			SET WARP to 0.
			SAS ON.
			SET SASMODE to "RETROGRADE".
			prepLand().
			set mode to mode + 1.
		}
	}
	else if mode = 9 {
		if ALT:RADAR < 400 {
			antennaOn().
			SAS off.
			set mode to mode + 1.
		}
	}
	else if mode = 10 {
		if ALT:RADAR < 220 {
			set v to VERTICALSPEED.
			set VDes to -5.
			if ALT:RADAR < 30 {
				set VDes to -2.
			}
			if v < VDes {
				set TVAL to MIN(TVAL + 0.05, 0.45).
				wait 0.1.
			} else if v > VDes {
				set TVAL to MAX(TVAL - 0.02, 0.15).
				wait 0.1.
			}
			set stat to S:STATUS.
			if stat = "LANDED" or stat = "SPLASHED" {
				jetsOff().
				SAS on.
				set SASMODE to "STABILITYASSIST".
				wait 0.5.
				set mode to 20.
			}
		}
	}
	
	else if mode = 20 {
		set TVAL to 0.
		unlock steering.
		set mode to 0.
	}
	lock throttle to TVAL.
	print "MODE:    " + mode + "      " at (5,4).
	print "LNG:     " + round(lng*100)/100 + "     " at (5,5).
}
