// landing script for SSTO2-0.
set CorrectionLng to 90.
// assume current orbit is 100x100km.
set DPeri to 45000. // m. Desired periapsis.
set feather to false.
copy landingskel from archive.
run landingskel.
