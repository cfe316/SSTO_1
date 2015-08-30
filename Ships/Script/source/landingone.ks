// landing script for SSTO1-2.
set CorrectionLng to 98.5.
// assume current orbit is 100x100km.
set DPeri to 45000. // m. Desired periapsis.
set feather to True. // feather control surfaces in atmosphere.
copy landingskel from archive.
run landingskel.
