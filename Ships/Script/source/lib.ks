// This is a 'library' file for both launching and landing, for all three ships.
set MU to KERBIN:MU.
set KR to KERBIN:RADIUS.
set g to MU/KR^2.
set k to 1000.
set S to SHIP.
function initialTurn {
	parameter y.
	parameter Y0.
	parameter th0.
	parameter n.
	set ts to Y0 * (TAN(th0) / n)^(n/(1-n)).
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
	set CA to APO + KR. // set currentApoapsis 
	set semimaj to (CA + PER + KR)/2. 
	set vDesired to SQRT(MU/CA).
	set orbEn to -mu/(2 * semimaj).
	set vApoCurrent to SQRT(2*(orbEn + MU/CA)).
	set dvn to vDesired - vApoCurrent. // delta V needed
	set acp to thrav() / SM. //acceleration possible
	set timeNeeded to dvn/acp.
	RETURN timeNeeded.
}.
function burnTimeNeeded {
	set Da to (APO + DPeri + 2 * KR)/2. 
	set CV to S:VELOCITY:ORBIT:MAG. // current velocity.
	set CR to ALTI + KR. // current radius.
	set DV to SQRT(2 * mu *(1/CR - 1/(2*Da))). // desired velocity. not Delta V.
	set deltaV to CV - DV.
	set Acc to thrav() / SM. // acceleration.
	set timeNeeded to deltaV/Acc.
	RETURN timeNeeded.
}.
function timeAtBurnCenter {
	set v to S:VELOCITY:ORBIT:MAG.
	set rad to ALTI + KR.
	set lngPerSec to v * 360 / (2 * constant():PI * rad).
	set lng to S:GEOPOSITION:LNG.
	set DeltaLongitude to BurnLng - lng.
	set timeTill to DeltaLongitude / lngPerSec.
	return TIME + timeTill.
}.
function antennaStow {
	SET topAntenna to S:PARTSTAGGED("topAntenna")[0].
	set md to topAntenna:GETMODULE("ModuleRTAntenna").
	if md:GETFIELD("status") = "Operational" {
		md:DOEVENT("deactivate").
	}
}.
function antennaOn {
	SET topAntenna to S:PARTSTAGGED("topAntenna")[0].
	set md to topAntenna:GETMODULE("ModuleRTAntenna").
	if md:GETFIELD("status") = "Off" {
		md:DOEVENT("activate").
	}
}.
function rokOn {
	set ptL to S:PARTSTAGGED("rok").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleEngines").
		if md:GETFIELD("status") = "Off" {
			md:DOACTION("activate engine", True).
		}
	}
}.
function rokOff{
	set ptL to S:PARTSTAGGED("rok").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleEngines").
		if md:GETFIELD("status") = "Nominal" {
			md:DOEVENT("shutdown engine").
		}
	}
}.
function jetsOff {
	set ptL to S:PARTSNAMED("turboFanEngine").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleEnginesFX").
		md:DOEVENT("shutdown engine").
	}
}.
function baysClosed {
	set ptL to S:PARTSNAMED("ServiceBay.125").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleAnimateGeneric").
		set event to md:ALLEVENTS[0].
		if event = "(callable) close, is KSPEVENT" {
			md:DOEVENT("close").
		}
	}
}.
function openIntakes {
	set ptL to S:PARTSNAMED("ramAirIntake").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleResourceIntake").
		if md:GETFIELD("status") = "Closed" {
			md:DOEVENT("open intake").
		}
	}
}.
function descentControlConfig {
	parameter bool.
	function ctlb {
		parameter b.
		for pt in ptL {
			set md to pt:GETMODULE("ModuleControlSurface").
			md:SETFIELD("state",b).
		}
	}.
	set ptL to S:PARTSNAMED("winglet3"). ctlb(bool).
	set ptL to S:PARTSNAMED("R8winglet"). ctlb(bool).
	set ptL to S:PARTSNAMED("tailfin"). ctlb(bool).
}. 
function airControlsOff {
	function ctlOff {
		for pt in ptL {
			set md to pt:GETMODULE("ModuleControlSurface").
			md:SETFIELD("pitch",True).
			md:SETFIELD("yaw",True).
			md:SETFIELD("roll",True).
		}
	}.
	set ptL to S:PARTSNAMED("winglet3"). ctlOff().
	set ptL to S:PARTSNAMED("R8winglet"). ctlOff().
	set ptL to S:PARTSNAMED("CanardController"). ctlOff().
	set ptL to S:PARTSTAGGED("feather"). ctlOff().
}. 
function popChutes {
	set ptL to S:PARTSNAMED("parachuteRadial").
	for pt in ptL {
		set md to pt:GETMODULE("ModuleParachute").
		md:DOEVENT("deploy chute").
	}
}.
function thrav { // thrust available
	LIST ENGINES IN ptL.
	local av is 0.
	FOR pt IN ptL { set av to av + pt:AVAILABLETHRUST. }
	return av.
}.
