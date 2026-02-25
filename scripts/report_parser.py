#RiscV-mini-SoC/scripts/report_parser.py
import re
import os
import sys

def parse_report(logfile, stage):
    if not os.path.exists(logfile):
        print(f"[Warning] {stage} log not found at {logfile}")
        return

    with open(logfile, 'r') as f:
        content = f.read()

    print(f"\n--- {stage.upper()} Report Summary ---")

    if stage == "synthesis":
        # Extract Cell Counts
        cells = re.search(r"Number of cells:\s+(\d+)", content)
        if cells: print(f"Total Standard Cells: {cells.group(1)}")
        
        # Breakdown of interesting cells for an electronics student
        registers = re.search(r"$_DFF_.*?\s+(\d+)", content)
        if registers: print(f"Total Flip-Flops: {registers.group(1)}")

    elif stage == "timing":
        # Extract Worst Negative Slack (WNS)
        # In OpenROAD, 'wns' is the most critical metric
        wns = re.search(r"wns\s+([-\d.]+)", content)
        tns = re.search(r"tns\s+([-\d.]+)", content)
        if wns: 
            val = float(wns.group(1))
            status = "MET" if val >= 0 else "VIOLATED"
            print(f"Worst Negative Slack: {val}ns ({status})")
        if tns: print(f"Total Negative Slack: {tns.group(1)}ns")

    elif stage == "area":
        # Extract Design Area from OpenROAD
        area = re.search(r"Design area\s+([\d.]+)\s+u\^2", content)
        util = re.search(fr"Utilization\s+([\d.]+)", content)
        if area: print(f"Total Design Area: {area.group(1)} um^2")
        if util: print(f"Core Utilization: {util.group(1)}%")

if __name__ == "__main__":
    # Update these paths to match your run_flow.sh output locations
    parse_report("output/synth.log", "synthesis")
    parse_report("output/floorplan.log", "area")
    parse_report("output/sta.log", "timing")