// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.
copy lib from archive.
run lib.

lock SM to S:MASS.
lock ALTI to S:ALTITUDE.
lock APO to S:APOAPSIS.
lock PER to S:PERIAPSIS.
set tr to R(0,0,-90). //Make craft fly upright. Perhaps set to R(0,0,0) if you're Eugene.

//Set desired orbit parameters.
set targetApoapsis to 100*k.
set targetPeriapsis to 100*k.

set thrCorrFac to MIN(1,(SM/35)). //design weight of ship in tons.

//set ascent parameters -------------
set n to 1/3.
set Y0 to 800. // height at which th0 is specified for the initial ascent curve
set th0 to 12. // speedup pitch angle
set th1 to 27. // climb pitch angle 
set turn1R to 8*k. // radius of circular turn up 
set Y2 to 22*k.
set th2 to 25. // thrust climb pitch
set turn2R to 20*k. // radius of turn to thrust climb
set rocketStart to 22*k.

// ts scales the ascent profile function
set ts to Y0 * (TAN(th0) / n)^(n/(1-n)).
function initialAscentProfile {
	parameter y.
	RETURN ARCTAN(n * (y / ts)^(1 - 1/n)).
}.

SET jet to S:PARTSNAMED("turboFanEngine")[0].
WHEN ALTI > rocketStart THEN {
	stage. // fire the rocket.

	WHEN jet:FLAMEOUT THEN {
		SET ptL to S:PARTSTITLED("Ram Air Intake").
		for pt in ptL {
			pt:GETMODULE("ModuleResourceIntake"):DOEVENT("close intake").
		}
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
RCS off.
lights off.
lock throttle to 0. // Throttle goes from 0.0 to 1.0
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
		lock throttle to 1. set TVAL to 1.
		wait 0.1.
		stage.
		PRINT "Counting down:".
		FROM {local countdown is 15.} until countdown = 0 STEP {SET countdown to countdown -1.} DO {
			PRINT "..." + countdown.
			WAIT 1.
		}
		stage.
		clearscreen.
		set mode to mode + 1.
	}

	else if mode = 2 { // start initial ascent power-law profile.
		set TVAL to 1.
		lock pitch to initialAscentProfile(ALTI).
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
		if ALTI > 50*k {
			lock steering to PROGRADE + tr.
		} else {
			lock pitch to th2.
			lock steering to heading(90,pitch) + tr.
		}
		if APO > targetApoapsis {
			set thrustOffTime to TIME.
			set mode to mode + 1.
		}
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
