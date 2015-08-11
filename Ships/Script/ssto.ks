// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.

// Start the script in a known configuration.
SAS on.
RCS off.
lights off.
lock throttle to 0. // Throttle goes from 0.0 to 1.0
gear off.

clearscreen.

//Set desired orbit parameters.
set targetApoapsis to 100000.
set targetPeriapsis to 100000.

set pitch to 90. // this variable will be monitored as the gravity turn happens
set climbPitch to 24. // the pitch for the power climb

set runmode to 2. // Safety in case we start mid-flight
if ALT:RADAR < 50 { // Guess is we are waiting for takeoff
	set runmode to 1.
}

SET jetEngine to SHIP:PARTSNAMED("turboFanEngine")[0].
WHEN jetEngine:GETMODULE("ModuleEnginesFX"):GETFIELD("status") = "Flame-out!" THEN {
	SET partsList to SHIP:PARTSTITLED("Ram Air Intake").
	for part in partsList {
		SET mod to part:GETMODULE("ModuleResourceIntake").
		mod:DOEVENT("close intake").
		// perhaps also switch off engines here.
		// or make it go into a runmode where we decrease throttle, just avoiding flameout.
	}
	set climbpitch to 30. // The power climb is done. The Nuke is already on. Pitch up to raise apo.

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

// This the the main prorgram loop. It runs until the program ends.
until runmode = 0 {

	if runmode = 1 { // Ship is on the launchpad
		lock steering to UP + R(0,0,90).
		// we don't just set TVAL here because this block
		// contains the countdown and launch. It only executes once.
		lock throttle to 1.
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

	else if runmode = 2 { // Fly UP to 100m before starting gravity turn.
		lock steering to heading(90,90) + R(0,0,90).
		set TVAL to 1.
		if SHIP:ALTITUDE > 100 {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 3 { // Start tilting for gravity turn.
		lock steering to heading(90,86) + R(0,0,90).
		if SHIP:ALTITUDE > 500 {
			// Go to Gravity Turn mode
			set runmode to runmode + 1.
		}
	}

	else if runmode = 4 { //Execute gravity turn: turn on SAS.
		unlock steering.
		SAS on.
		set SASMODE to "PROGRADE".
		lock pitch to 90 - vectorangle(UP:VECTOR, SHIP:FACING:FOREVECTOR).
		if pitch < climbPitch + 0.5 {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 5 { // the power climb 
		set SASMODE to "STABILITYASSIST".
		SAS off.
		lock steering to heading (90, climbPitch) + R(0,0,90).
		// we might want to level out around 20km and accelerate to max velocity before 
		// lighting the nuke and pitching up to await flameout
		if SHIP:ALTITUDE > 20000 {
			stage. // light the nuke engine.
			set runmode to runmode + 1.
		}
	}

	else if runmode = 6 { // Continuing the thrust into orbit.
		// The nuke is on and we are climbing at climbPitch.
		if SHIP:ALTITUDE > 50000 {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 7 { // The thrust into orbit.
		// pitch up to raise apoapsis.
		lock steering to heading (90, 30) + R(0,0,90).
		// wait until we are falling.
		if ETA:APOAPSIS > ETA:PERIAPSIS {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 8 { // The thrust into orbit.
		// wait until we are rising again.
		if ETA:PERIAPSIS > ETA:APOAPSIS {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 9 { // The thrust into orbit.
		if ETA:APOAPSIS > 20 {
			set runmode to runmode + 1.
		        lock steering to heading (90, 5) + R(0,0,90).
		}
	}

	else if runmode = 10 { // The thrust into orbit.
		if SHIP:APOAPSIS > targetApoapsis {
			set runmode to runmode + 1.
		}
	}

	else if runmode = 11 { // coast to apoapsis.
		lock steering to heading (90, 1) + R(0,0,90).
		set TVAL to 0.
		// could also physicswarp to 4x while we're still in atmo.
		if ETA:APOAPSIS < 60 {
			set runmode to 12.
			set apoapsisBeforeBurn to SHIP:APOAPSIS.
		}
	}

	else if runmode = 12 {
		if ETA:APOAPSIS < 6 or VERTICALSPEED < 0 {
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
}

