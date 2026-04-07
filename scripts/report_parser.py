import re
import os

def parse_report(logfile, stage):
    if not os.path.exists(logfile):
        # Important for your seminar: ensure these files are created by your run_flow.sh
        return

    with open(logfile, 'r') as f:
        content = f.read()

    print(f"\n--- {stage.upper()} Report Summary ---")

    if stage == "synthesis":
        # Yosys output format for total cells
        cells = re.search(r"Number of cells:\s+(\d+)", content)
        if cells: print(f"Total Standard Cells: {cells.group(1)}")
        
        # Count Flip-Flops (Registers) - crucial for an electronics project
        dffs = re.findall(r"sky130_fd_sc_hd__df\w+", content)
        if dffs: print(f"Total Flip-Flops detected: {len(dffs)}")

    elif stage == "area":
        # OpenROAD 'initialize_floorplan' or 'global_placement' output
        area = re.search(r"Core area:\s+([\d.]+)", content)
        util = re.search(r"Utilization:\s+([\d.]+)\s+%", content)
        if area: print(f"Core Area: {area.group(1)} um^2")
        if util: print(f"Final Utilization: {util.group(1)}%")

    elif stage == "timing":
        # Post-Route STA patterns
        wns = re.search(r"wns\s+([-\d.]+)", content)
        slack = re.search(r"slack\s+\((MET|VIOLATED)\)\s+([-\d.]+)", content)
        
        if wns: print(f"Worst Negative Slack (WNS): {wns.group(1)}ns")
        if slack: print(f"Sign-off Timing Status: {slack.group(1)} (Slack: {slack.group(2)}ns)")

    elif stage == "cts":
        # Clock Tree results are vital for electronics students
        skew = re.search(r"setup skew\s+([-\d.]+)", content)
        if skew: print(f"Clock Skew: {skew.group(1)}ns")

    elif stage == "route":
        # Total amount of copper/metal used
        wirelength = re.search(r"Total wire length\s+=\s+([\d.]+)\s+um", content)
        if wirelength: print(f"Total Wire Length: {wirelength.group(1)} um")

    elif stage == "signoff":
        # The final 'Pass/Fail' of the project
        wns = re.search(r"wns\s+([-\d.]+)", content)
        status = re.search(r"slack\s+\((MET|VIOLATED)\)", content)
        if wns: print(f"Final WNS: {wns.group(1)}ns")
        if status: print(f"Sign-off Status: {status.group(1)}")


if __name__ == "__main__":
    # Ensure these paths match the 'tee' output in your run_flow.sh
    parse_report("output/synth.log", "synthesis")
    parse_report("output/placement.log", "area")
    parse_report("output/route.log", "timing")
    parse_report("output/cts.log", "cts")
    parse_report("output/route.log", "route")
    parse_report("output/signoff.log", "signoff")   