#!/bin/bash
make clean
make synth
make floorplan
make pdn
make placement
make cts
make route
make sta
make signoff
make gds
make report
