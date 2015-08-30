// skeleton launch script.
// Assumes the first three stages like
// 1) Jets
// 2) Release launch clamps
// 3) Rocket engine
// needs predefined:
// n, th0, th1, th2 
// Y0, Y2
// turn1R, turn2R
// rocketStart
// thrCorrFac
// targetApoapsis, targetPeriapsis
// tr (rotation to make the craft fly upright)
// SM (SHIP:MASS)
// ALTI (ALTITUDE)
// APO (APOAPSIS)
// PER (PERIAPSIS)

SET jet to S:PARTSNAMED("turboFanEngine")[0].
WHEN ALTI > rocketStart THEN {
	stage. // fire the rocket.

	WHEN jet:FLAMEOUT THEN {
		//SET ptL to S:PARTSTITLED("Ram Air Intake").
		//for pt in ptL {
		//	pt:GETMODULE("ModuleResourceIntake"):DOEVENT("close intake").
		//}
		// this nested WHEN will start checking after the first one happens.
		// That way the CPU only has to check for one WHEN event at a time.
		WHEN ALTI > 70010 THEN {
			SET pt to S:PARTSTAGGED("airstream")[0].
			pt:GETMODULE("ModuleProceduralFairing"):DOEVENT("DEPLOY").

			SET pt to S:PARTSTAGGED("topAntenna")[0].
			pt:GETMODULE("ModuleRTAntenna"):DOEVENT("ACTIVATE").
		}
	}
}

// main script begin.
// Start the script in a known configuration.
SAS off.
gear off.

clearscreen.
set mode to 1.
set pitch to 90. // for printing reasons these need a default value.
set twr to 1.
// This the the main prorgram loop. It runs until the program ends.
until mode = 0 {
	
	if mode = 1 { // Ship is on the launchpad
		// we don't just set TVAL here because this block
		// contains the countdown and launch. It only executes once.
		lock throttle to 1. set TVAL to 1. wait 0.1.
		stage.
		PRINT "Counting down:".
		FROM {local countdown is countStart.} until countdown = 0 STEP {SET countdown to countdown -1.} DO {
			PRINT "..." + countdown.
			WAIT 1.
		}
		stage.
		clearscreen.
		set mode to mode + 1.
	}

	else if mode = 2 { // start initial ascent power-law profile.
		set TVAL to 1.
		lock pitch to initialturn(ALTI, Y0, th0, n).
		lock steering to heading(90,pitch) + tr.
		if ALTI > Y0 {
			set mode to mode + 1.
		}
	}

	else if mode = 3 { // go in a straight line until the turn starts.
		if MAXTHRUST / (SM * g) < 2 {
		lock pitch to th0.
		} else {
			set turnUCY to ALTI + turn1R * COS(th0).
			set turnUR to turn1R.
			set mode to mode + 1.
		}
	}

	else if mode = 4 { // do the turn.
		lock pitch to MIN(turnUp(ALTI),th1).
		if ALTI > Y2 {
			// Go to power climb
			set turnDCY to Y2 - turn2R * COS(th1).
			set turnDR to turn2R.
			set mode to mode +2.
		}
	}
	
	else if mode = 6 { // do the turn.
		lock pitch to turnDown(ALTI).
		if pitch < th2 {
			// Go to thrust into orbit 
			set mode to mode +1.
		}
	}

	else if mode = 7 { // thrust to orbit.
		thrustToOrbit().
	}

	else if mode = 8 { // coast to space.
		lock steering to PROGRADE + tr.
		set TVAL to 0.
		if (TIME - thrustOffTime) > 10 {
			set WARPMODE TO "PHYSICS".
			set WARP TO 3.
			set mode to mode + 1.
		}
	}

	else if mode = 9 { //warp to edge of atmo.
		if ALTI > 69500 {
			set WARP to 0.
			set WARPMODE to "RAILS".
		}
		if ALTI > 70500 {
			airControlsOff().
			set mode to mode + 1.
		}
	}

	else if mode = 10 { //apoapsis correction.
		lock steering to PROGRADE + tr.
		set TVAL to 0.05.
		if APO > targetApoapsis {
			set mode to mode + 1.
		}
	}

	else if mode = 11 {
		lock steering to heading(90,0) + tr.
		lock TVAL to 0.
		SET WARP TO 4.
		if ETA:APOAPSIS < 120 {
			SET WARP TO 0.
			// calculate burn time required
			set timeNeeded to circularizationTime().
			set currAp to APO.
			set mode to mode + 1.
		}
	}

	else if mode = 12 {
		if ETA:APOAPSIS < timeNeeded/2 or VERTICALSPEED < 0 {
			set TVAL to 1.
		}
		if (PER > targetPeriapsis * 0.995) or (APO > (currAp + 1*k)){
			set TVAL to 0.
			set mode to 20.
		}
	}

	//end program
	else if mode = 20 {
		set TVAL to 0.
		unlock steering.
		set mode to 0.
	}

	if ALTI < 15*k {
		lock throttle to TVAL * thrCorrFac.
	} else {
		lock throttle to TVAL.
	}

	print "MODE:    " + mode + "      " at (5,4).
}
