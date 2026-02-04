#pd/Makefile
# Makefile for Physical Design Flow

include config.mk

# Path to the OpenROAD flow script
FLOW_SCRIPT = $(PROJECT_HOME)/scripts/run_flow.sh

.PHONY: synth floorplan clean

synth:
	@echo "Starting Synthesis for $(DESIGN_NAME)..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step synth

floorplan:
	@echo "Starting Floorplan for $(DESIGN_NAME)..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step floorplan

# ... existing targets ...
pdn:
	@echo "Starting PDN generation..."
	bash $(FLOW_SCRIPT) --design $(DESIGN_NAME) --step pdn
clean:
	@echo "Cleaning up project files..."
	rm -rf output/*.v
	rm -rf output/*.def
	rm -rf output/*.log