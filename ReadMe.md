# Digital IC Design Workspace Template

This repository provides a standardized, scalable, and modular directory structure for Digital IC Design and FPGA projects. 

The core philosophy of this workspace is **Separation of Concerns**: isolating the dynamic design data (RTL) from the static tool execution flows (Scripts), and ensuring all tool executions are performed out-of-source to keep the codebase clean.

## 📂 Directory Structure

```text
workspace_root/
│
├── scripts/                  # 🔒 STATIC: Reusable flow automation
│   ├── syn/                  # Independent Synthesis scripts (Tcl, Makefiles)
│   └── pnr/                  # Independent Place & Route scripts (Tcl, Makefiles)
│
├── design_data/              # 🔄 DYNAMIC: Source code and constraints
│   └── examples/             # Individual hardware projects/IPs
│       ├── project_a/        
│       │   ├── src/          # RTL files (.v, .sv, .vhd)
│       │   └── constraints/  # Timing/Physical constraints (.sdc, .xdc)
│       └── project_b/        
│           ├── src/
│           └── constraints/
│
└── run_workspace/            # 🚀 EXECUTION: Out-of-source build directories
    ├── .gitignore            # Keep this directory out of version control
    ├── run_syn_project_a/    # Working directory for Project A synthesis
    └── run_pnr_project_b/    # Working directory for Project B PnR