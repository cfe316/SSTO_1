// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.
switch to 0.
set fileNameSuffix to "10".
// Start the script in a known configuration.
SAS off.
RCS off.
lights off.
lock throttle to 0. // Throttle goes from 0.0 to 1.0
gear off.

set littleg to 9.81.

clearscreen.

//Set desired orbit parameters.
set targetApoapsis to 100000.
set targetPeriapsis to 100000.

set targetApoCorrection to 3000.

//set ascent parameters -------------
set n to 1.0/3.
set Y0 to 800. // height at which th0 is specified for the initial ascent curve
set th0 to 10. // initial climb pitch angle
set th1 to 22.
set turn1R to 15000. // radius of circular turn up 
set Y3 to 25000.
set th2 to 25. 
set turn2R to 20000. // radius of 2nd circular turn up.

// ts scales the ascent profile function
set ts to Y0 * (TAN(th0) / n)^(n/(1-n)).
function initialAscentProfile {
	parameter y.
	RETURN ARCTAN(n * (y / ts)^(1 - 1/n)).
}.

function turnUp { //a turn upward
	parameter y.
	if y < (turnCY - turnR) {
		RETURN 0.
	} else if y > turnCY {
		RETURN 90.
	} else {
		RETURN ARCTAN(SQRT(turnR^2 - (y - turnCY)^2)/(turnCY - y)).
	}
}.

SET jetEngine to SHIP:PARTSNAMED("turboFanEngine")[0].
WHEN ALTITUDE > 20000 THEN {
	stage. // fire the nuke.

	WHEN jetEngine:GETMODULE("ModuleEnginesFX"):GETFIELD("status") = "Flame-out!" THEN {
		SET partsList to SHIP:PARTSTITLED("Ram Air Intake").
		for part in partsList {
			SET mod to part:GETMODULE("ModuleResourceIntake").
			mod:DOEVENT("close intake").
			// perhaps also switch off engines here.
			// or make it go into a runmode where we decrease throttle, just avoiding flameout.
		}
		// this nested WHEN will start checking after the first one happens.
		// That way the CPU only has to check for one WHEN event at a time.
		WHEN SHIP:ALTITUDE > 70010 THEN {
			// perhaps we could leave the fairing behind earlier, 
			// but it's pretty lightweight... I don't even see a change in 
			//deltaV in KER when it fires..
			SET fairingpart to SHIP:PARTSTAGGED("airstream")[0].
			fairingpart:GETMODULE("ModuleProceduralFairing"):DOEVENT("DEPLOY").

			SET topAntenna to SHIP:PARTSTAGGED("topAntenna")[0].
			topAntenna:GETMODULE("ModuleRTAntenna"):DOEVENT("ACTIVATE").
		}
	}
}

set runmode to 1.
set pitch to 90.
set twr to 1.
// This the the main prorgram loop. It runs until the program ends.
until runmode = 0 {
	
	if runmode = 1 { // Ship is on the launchpad
		lock steering to UP + R(0,0,90).
		// we don't just set TVAL here because this block
		// contains the countdown and launch. It only executes once.
		lock throttle to 1. set TVAL to 1.
		wait 0.1.
		stage.
		PRINT "Counting down:".
		FROM {local countdown is 12.} until countdown = 0 STEP {SET countdown to countdown -1.} DO {
			PRINT "..." + countdown.
			WAIT 1.
		}
		stage.
		clearscreen.
		set runmode to runmode + 1.
	}

	else if runmode = 2 { // start initial ascent power-law profile.
		set TVAL to 1.
		lock pitch to initialAscentProfile(SHIP:ALTITUDE).
		lock steering to heading(90,pitch) + R(0,0,90).
		if SHIP:ALTITUDE > Y0 {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 3 { // go in a straight line until the turn starts.
		set shipmass to SHIP:MASS * 1000.
		set thrust to 2 * jetEngine:THRUST * 1000.
		set twr to thrust / (shipmass * littleg).

		if twr < 2 {
		lock pitch to th0.
		} else {
			set turnCY to SHIP:ALTITUDE + turn1R * COS(th0).
			set turnR to turn1R.
			set runmode to runmode + 1.
		}
	}

	else if runmode = 4 { // do the turn.
		lock pitch to turnUp(SHIP:ALTITUDE).
		if pitch > th1 {
			// Go to power climb
			set runmode to runmode +1.
		}
	}

	else if runmode = 5 { //power climb.
		lock pitch to th1.
		if SHIP:ALTITUDE > Y3 {
			// Go to turn upwards 
			set turnCY to SHIP:ALTITUDE + turn2R * COS(th1).
			set turnR to turn2R.
			set runmode to runmode +1.
		}
	}

	else if runmode = 6 { // do the turn.
		lock pitch to turnUP(SHIP:ALTITUDE).
		if pitch > th2 {
			// Go to thrust into orbit 
			set runmode to runmode +1.
		}
	}

	else if runmode = 7 { // thrust to orbit.
		lock pitch to th2.
		if SHIP:APOAPSIS > targetApoapsis + targetApoCorrection  {
			set runmode to runmode + 1.
		}
	}
	else if runmode = 8 { // coast to space.
		lock steering to SHIP:PROGRADE + R(0,0,90).
		set TVAL to 0.
		// could also physicswarp to 4x while we're still in atmo.
		if SHIP:ALTITUDE > 70000 {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 9 { //apoapsis correction.
		lock steering to SHIP:PROGRADE + R(0,0,90).
		set TVAL to 0.05.
		if SHIP:APOAPSIS > targetApoapsis {
			set runmode to runmode + 1.
		}
	}
	
	else if runmode = 10 {
		lock steering to heading(90,0) + R(0,0,90).
		lock TVAL to 0.
		SET WARP TO 4.

		if ETA:APOAPSIS < 60 {
			SET WARP TO 0.
			set runmode to 11.
			set apoapsisBeforeBurn to SHIP:APOAPSIS.
		}
	}

	else if runmode = 11 {
		if ETA:APOAPSIS < 8 or VERTICALSPEED < 0 {
			set TVAL to 1.
		}
		if (SHIP:PERIAPSIS > targetPeriapsis * 0.98) or (SHIP:APOAPSIS > (apoapsisBeforeBurn + 1000)){
			set TVAL to 0.
			set runmode to 20.
		}
	}

	//end program
	else if runmode = 20 {
		set TVAL to 0.
		unlock steering.
		set runmode to 0.
	}

	lock throttle to TVAL.

	print "RUNMODE:    " + runmode + "      " at (5,4).
	print "pitch:      " + pitch + "       "  at (5,5).
	print "ts:         " + ts + " " at (5,6).
	print "Y0          " + Y0 + " " at (5,7).
	print "twr         " + twr + " " at (5,9).
	set timeseconds to time:seconds.
	if MOD(FLOOR(timeseconds * 10),10) = 0 {
	LOG time:seconds + " " + runmode + " " + SHIP:ALTITUDE + " " + SHIP:VELOCITY:ORBIT:MAG + " " + SHIP:APOAPSIS + " " + pitch + " " + SHIP:PERIAPSIS to "launchlog"+fileNameSuffix+".txt".
	}
}

