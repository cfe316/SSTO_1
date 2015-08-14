// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.
switch to 0.
set fileNameSuffix to "04".
// Start the script in a known configuration.
SAS off.
RCS off.
lights off.
lock throttle to 0. // Throttle goes from 0.0 to 1.0
gear off.

clearscreen.

//Set desired orbit parameters.
set targetApoapsis to 100000.
set targetPeriapsis to 100000.

//set ascent parameters -------------
set n to 1.0/2.
set Y0 to 1500. // height at which th0 is specified for the initial ascent curve
set th0 to 30. // initial climb pitch angle
// ts scales the ascent profile function
set ts to Y0 * (TAN(th0) / n)^(n/(1-n)).
set X0 to ts * (Y0 / ts)^(1/n).
set b0 to Y0 - TAN(th0) * X0. 
// go in a straight line from (X0, Y0) to (X1, Y1). ---------
set Y1 to 4000.
set th1 to 24.
set turnR to 15000. // radius of circular turn toward level.
//-----------------------------------
set X1 to (Y1 - b0)/TAN(th0).
// find the centerpoint of the circular turn.
set turnCX to X1 + turnR * SIN(th0).
set turnCY to X1 - turnR * COS(th0).
set X2 to turnCX - turnR * SIN(th1). // X2, Y2 is location after the first turn.
set Y2 to turnCY + turnR * COS(th1). 
set b1 to Y2 - TAN(th1) * X2.
set Y3 to 25000.
set th2 to 25.
set turn2R to 20000.
set X3 to (Y3 - b1)/TAN(th1).
set turn2CX to X3 - turn2R * SIN(th1).
set turn2CY to Y3 + turn2R * COS(th1).
set X4 to turn2CX + turn2R * SIN(th2).
set Y4 to turn2CY - turn2R * COS(th2).

function initialAscentProfile {
	parameter y.
	RETURN ARCTAN(n * (y / ts)^(1 - 1/n)).
}.

function turn1 {
	parameter y.
	RETURN ARCTAN(SQRT(turnR^2 - (y - turnCY)^2)/(y-turnCY)).
}.

function turn2 {
	parameter y.
	RETURN ARCTAN(SQRT(turn2R^2 - (y - turn2CY)^2)/(turn2CY - y)).
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
					
					SET WARP TO 4.
					WHEN ETA:APOAPSIS < 120 THEN {
						SET WARP TO 0.
					}
				}
	}
}

set runmode to 1.
set pitch to 90.
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
		FROM {local countdown is 10.} until countdown = 0 STEP {SET countdown to countdown -1.} DO {
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
		lock pitch to th0.
		if SHIP:ALTITUDE > Y1 {
			// Go to circular turn mode
			set runmode to runmode + 1.
		}
	}

	else if runmode = 4 { // do the turn.
		lock pitch to turn1(SHIP:ALTITUDE).
		if SHIP:ALTITUDE > Y2 {
			// Go to power climb
			set runmode to runmode +1.
		}
	}

	else if runmode = 5 { //power climb.
		lock pitch to th1.
		if SHIP:ALTITUDE > Y3 {
			// Go to turn upwards 
			set runmode to runmode +1.
		}
	}

	else if runmode = 6 { // do the turn.
		lock pitch to turn2(SHIP:ALTITUDE).
		if SHIP:ALTITUDE > Y4 {
			// Go to thrust into orbit 
			set runmode to runmode +1.
		}
	}

	else if runmode = 7 { // thrust to orbit.
		lock pitch to th2.
		if SHIP:APOAPSIS > targetApoapsis  {
			set runmode to 10.
		}
	}

	//end program
	else if runmode = 10 {
		set TVAL to 0.
		unlock steering.
		set runmode to 0.
	}

	lock throttle to TVAL.

	print "RUNMODE:    " + runmode + "      " at (5,4).
	print "pitch:      " + pitch + "       "  at (5,5).
	print "ts:         " + ts + " " at (5,6).
	print "Y0          " + Y0 + " " at (5,7).
	print "Y1          " + Y1 + " " at (5,8).
	print "Y2          " + Y2 + " " at (5,9).
	print "Y3          " + Y3 + " " at (5,10).
	set timeseconds to time:seconds.
	if MOD(FLOOR(timeseconds * 10),10) = 0 {
	LOG time:seconds + " " + runmode + " " + SHIP:ALTITUDE + " " + SHIP:VELOCITY:ORBIT:MAG + " " + SHIP:APOAPSIS + " " + pitch to "launchlog"+fileNameSuffix+".txt".
	}
}

