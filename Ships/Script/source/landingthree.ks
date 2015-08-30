// landing script for SSTO2-0.
set CorrectionLng to 85.
// assume current orbit is 100x100km.
set DPeri to 45*k. // m. Desired periapsis.
set feather to True.
copy landingskel from archive.
run landingskel.
