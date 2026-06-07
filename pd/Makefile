#pd/Makefile
# Makefile for Physical Design Flow

include config.mk

# Path to the OpenROAD flow script
FLOW_SCRIPT = $(PROJECT_HOME)/scripts/run_flow.sh

.PHONY: synth floorplan pdn placement cts route sta signoff gds report gui clean

synth:
	@echo "Starting Synthesis for $(DESIGN_NAME)..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step synth | tee output/synth.log

floorplan:
	@echo "Starting Floorplan for $(DESIGN_NAME)..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step floorplan | tee output/floorplan.log

# ... existing targets ...
pdn:
	@echo "Starting PDN generation..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step pdn | tee output/pdn.log

placement:
	@echo "Starting Placement..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step placement | tee output/placement.log

cts:
	@echo "Building Clock Tree..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step cts | tee output/cts.log

route:
	@echo "Routing the MiniSoC..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step route | tee output/route.log

sta:
	@echo "Checking Timing..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step sta | tee output/sta.log

signoff:
	@echo "Performing Signoff Checks..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step signoff | tee output/signoff.log

gds:
	@echo "Generating GDS file..."
	magic -dnull -noconsole -rcfile sky130A_fixed.magicrc merge.tcl | tee output/gds.log

gui:
	@echo "Opening OpenROAD GUI with Timing and IR Drop data..."
	/home/manal/OpenROAD/build/install/bin/openroad -gui gui.tcl

report:	
	@echo "Analyzing Design Metrics..."
	python3 $(PROJECT_HOME)/scripts/report_parser.py

clean:
	@echo "Cleaning up project files..."
	rm -rf output/*.v
	rm -rf output/*.def
	rm -rf output/*.log