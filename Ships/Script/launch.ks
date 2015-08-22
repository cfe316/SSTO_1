// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.

set tr to R(0,0,-90). //Make craft fly upright. Perhaps set to R(0,0,0) if you're Eugene.

set g to KERBIN:MU / KERBIN:RADIUS^2.
set mu to KERBIN:MU.

//Set desired orbit parameters.
set targetApoapsis to 100000.
set targetPeriapsis to 100000.

set sm to SHIP:MASS.
set thrCorrFac to MIN(1,(sm/17.565)). //design weight of ship in tons.

//set ascent parameters -------------
set n to 1.0/3.
set Y0 to 800. // height at which th0 is specified for the initial ascent curve
set th0 to 12. // speedup pitch angle
set th1 to 26. // climb pitch angle 
set turn1R to 8000. // radius of circular turn up 
set turn2R to 25000. // level off to powerclimb angle
set Y2 to 10000. // powerclimb start height.
set th2 to 26. // powerclimb pitch angle
set Y3 to 22000.
set th3 to 24. // thrust climb pitch
set turn3R to 20000. // radius of turn to thrust climb
set nukeStart to 20000.

set turn2CY to Y2 - turn2R * COS(th2).

// ts scales the ascent profile function
set ts to Y0 * (TAN(th0) / n)^(n/(1-n)).
function initialAscentProfile {
	parameter y.
	RETURN ARCTAN(n * (y / ts)^(1 - 1/n)).
}.

function turnUp { //a turn upward
	parameter y.
	if y < (turnUCY - turnUR) {
		RETURN 0.
	} else if y > turnUCY {
		RETURN 90.
	} else {
		RETURN ARCTAN(SQRT(turnUR^2 - (y - turnUCY)^2)/(turnUCY - y)).
	}
}.

function turnDown { // a turn downward
	parameter y.
	if y < (turnDCY) {
		RETURN 90.
	} else if y > (turnDCY + turnDR) {
		RETURN 0.
	} else {
		RETURN ARCTAN(SQRT(turnDR^2 - (y - turnDCY)^2)/(y- turnDCY)).
	}
}.

function circularizationTime {
	set currentApo to SHIP:APOAPSIS + KERBIN:RADIUS.
	set semimaj to (currentApo + SHIP:PERIAPSIS + KERBIN:RADIUS)/2. 
	set vDesired to SQRT(mu / currentApo).
	set orbEn to -mu/(2 * semimaj).
	set vApoCurrent to SQRT(2*(orbEn + mu/currentApo)).
	set deltaVNeeded to vDesired - vApoCurrent.
	set nukeThrust to 60.
	set shipmass to SHIP:MASS.
	set accPoss to nukeThrust / shipmass.
	set timeNeeded to deltaVNeeded/accPoss.
	RETURN timeNeeded.
}.

SET jetEngine to SHIP:PARTSNAMED("turboFanEngine")[0].
WHEN ALTITUDE > nukeStart THEN {
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
			SET fairingpart to SHIP:PARTSTAGGED("airstream")[0].
			fairingpart:GETMODULE("ModuleProceduralFairing"):DOEVENT("DEPLOY").

			SET topAntenna to SHIP:PARTSTAGGED("topAntenna")[0].
			topAntenna:GETMODULE("ModuleRTAntenna"):DOEVENT("ACTIVATE").
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
		FROM {local countdown is 12.} until countdown = 0 STEP {SET countdown to countdown -1.} DO {
			PRINT "..." + countdown.
			WAIT 1.
		}
		stage.
		clearscreen.
		set mode to mode + 1.
	}

	else if mode = 2 { // start initial ascent power-law profile.
		set TVAL to 1.
		lock pitch to initialAscentProfile(SHIP:ALTITUDE).
		lock steering to heading(90,pitch) + tr.
		if SHIP:ALTITUDE > Y0 {
			set mode to mode + 1.
		}
	}

	else if mode = 3 { // go in a straight line until the turn starts.
		set shipmass to SHIP:MASS.
		set thrust to 2 * jetEngine:THRUST.
		set twr to thrust / (shipmass * g).

		if twr < 2 {
		lock pitch to th0.
		} else {
			set turnUCY to SHIP:ALTITUDE + turn1R * COS(th0).
			set turnUR to turn1R.
			set turnDCY to turn2CY.
			set turnDR to turn2R.
			set mode to mode + 1.
		}
	}

	else if mode = 4 { // do the turn.
		lock pitch to MIN(MIN(turnUp(SHIP:ALTITUDE),th1), turnDown(SHIP:ALTITUDE)).
		if SHIP:ALTITUDE > Y2 {
			// Go to power climb
			set mode to mode +1.
		}
	}

	else if mode = 5 { //power climb.
		lock pitch to th2.
		if SHIP:ALTITUDE > Y3 {
			// Go to turn upwards 
			set turnDCY to Y3 - turn3R * COS(th2).
			set turnDR to turn3R.
			set mode to mode +1.
		}
	}

	else if mode = 6 { // do the turn.
		lock pitch to turnDown(SHIP:ALTITUDE).
		if pitch < th3 {
			// Go to thrust into orbit 
			set mode to mode +1.
		}
	}

	else if mode = 7 { // thrust to orbit.
		if ETA:APOAPSIS > 10 AND SHIP:PERIAPSIS > -20000 {
			lock steering to SHIP:PROGRADE + tr.
		} else {
			lock pitch to th3.
			lock steering to heading(90,pitch) + tr.
		}
		if SHIP:APOAPSIS > targetApoapsis {
			set thrustOffTime to TIME.
			set mode to mode + 1.
		}
	}
	else if mode = 8 { // coast to space.
		lock steering to SHIP:PROGRADE + tr.
		set TVAL to 0.
		if (TIME - thrustOffTime) > 10 {
			set WARPMODE TO "PHYSICS".
			set WARP TO 3.
			set mode to mode + 1.
		}
	}

	else if mode = 9 { //warp to edge of atmo.
		if SHIP:ALTITUDE > 69500 {
			set WARP to 0.
			set WARPMODE to "RAILS".
		}
		if SHIP:ALTITUDE > 70500 {
			set mode to mode + 1.
		}
	}
	
	else if mode = 10 { //apoapsis correction.
		lock steering to SHIP:PROGRADE + tr.
		set TVAL to 0.05.
		if SHIP:APOAPSIS > targetApoapsis {
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
			set mode to mode + 1.
		}
	}

	else if mode = 12 {
		if ETA:APOAPSIS < timeNeeded/2 or VERTICALSPEED < 0 {
			set TVAL to 1.
		}
		if (SHIP:PERIAPSIS > targetPeriapsis * 0.995) or (SHIP:APOAPSIS > (currentApo + 1000)){
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

	if SHIP:ALTITUDE < 15000 {
		lock throttle to TVAL * thrCorrFac.
	} else {
		lock throttle to TVAL.
	}

	print "MODE:    " + mode + "      " at (5,4).
	print "pitch:      " + round(pitch*100)/100 + "       "  at (5,5).
	print "twr         " + round(twr*100)/100 + "       " at (5,6).
}
