// This script is to launch the SSTO1-1, an 18-ton, 4-ton-payload SSTO craft.
copy lib from archive.
run lib.

lock SM to MASS.
lock ALTI to ALTITUDE.
lock APO to APOAPSIS.
lock PER to PERIAPSIS.
set tr to R(0,0,-90). //Make craft fly upright. Perhaps set to R(0,0,0) if you're Eugene.

//Set desired orbit parameters.
set targetApoapsis to 100*k.
set targetPeriapsis to 100*k.

set desM to 17.565. // Design mass of the ship
set thrCorrFac to MIN(1,(SM/desM)). // throttle de-rating factor so ship doesn't go too fast.

//set ascent parameters -------------
set n to 1/3.  // power law for curve; curve is the shape of y = x^n
set Y0 to 800. // height at which th0 is specified for the initial ascent curve
set th0 to 12. // speedup pitch angle
set th1 to 26. // jet climb pitch angle 
set turn1R to 8*k. // radius of circular turn up 
set Y2 to 22*k. // Start turn down
set th2 to 24. // thrust climb to orbit pitch
set turn2R to 20*k. // radius of turn to thrust climb
set rocketStart to 20*k.

function thrustToOrbit {
	if ETA:APOAPSIS > 10 AND PER > -20*k {
		lock steering to PROGRADE + tr.
	} else {
		lock pitch to th2.
		lock steering to heading(90,pitch) + tr.
	}
	if APO > targetApoapsis {
		set thrustOffTime to TIME.
		set mode to mode + 1.
	}
}.

copy launchskel from archive.
run launchskel.
