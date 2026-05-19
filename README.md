# RISC-V Pipeline with Cache Memory Subsystem

A fully pipelined **32-bit RISC-V (RV32I)** processor implemented in SystemVerilog, featuring a two-level (L1 + L2) cache memory hierarchy. Designed and verified for the **Digilent Zybo Z7-20** FPGA board using Xilinx Vivado.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Pipeline Stages](#pipeline-stages)
  - [Hazard Unit](#hazard-unit)
  - [Cache Subsystem](#cache-subsystem)
- [Project Structure](#project-structure)
- [Supported Instructions](#supported-instructions)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Creating the Vivado Project](#creating-the-vivado-project)
  - [Running Simulation](#running-simulation)
- [Constraints](#constraints)
- [Testing](#testing)

---

## Overview

This project implements a classic **5-stage in-order pipeline** for the RISC-V RV32I ISA, extended with a two-level cache subsystem between the pipeline and the data memory (DMEM). Key highlights:

- 5-stage pipeline: **IF → ID → EX → MEM → WB**
- **Data forwarding** (MEM-to-EX and WB-to-EX) to resolve most data hazards without stalls
- **Load-use stall** detection for unavoidable one-cycle penalties
- **Branch/jump flush** to handle control hazards
- **L1 cache** — 64-set, 2-way set-associative, LRU replacement policy
- **L2 cache** — 64-set, 4-way set-associative, MRU-based replacement policy
- Pipeline stalls automatically on cache misses until the requested data is fetched from DMEM
- Vivado TCL script for one-command project setup

---

## Architecture

### Pipeline Stages

```
┌────────┐   ┌────────┐   ┌─────────┐   ┌────────┐   ┌────────┐
│  IF    │──▶│  ID    │──▶│   EX    │──▶│  MEM   │──▶│  WB    │
│ Fetch  │   │ Decode │   │ Execute │   │ Memory │   │ Write  │
│        │   │        │   │         │   │        │   │  Back  │
└────────┘   └────────┘   └─────────┘   └────────┘   └────────┘
                 ▲               │            │
                 └───────────────┴────────────┘
                         Forwarding paths
```

The pipeline is controlled by the `controller` module, which propagates decoded control signals (RegWrite, MemWrite, ALUControl, ResultSrc, ImmSrc, Branch, Jump, ALUSrcB) across pipeline registers from ID through WB.

### Hazard Unit

The `hazard_unit` module handles all pipeline hazards:

| Hazard Type | Detection | Resolution |
|---|---|---|
| RAW (general) | rs1/rs2 in EX match rd in MEM or WB | Forward from MEM or WB stage |
| Load-use | `lw` in EX, destination matches ID source | Stall IF + ID, flush EX |
| Control (branch/jump) | PCSrc_E asserted | Flush ID |

Forwarding is implemented for both source operands (ForwardA\_E, ForwardB\_E) with 2-bit mux select signals:
- `2'b10` → forward from MEM stage
- `2'b01` → forward from WB stage
- `2'b00` → use register file output

### Cache Subsystem

The `cache_subsystem` module integrates L1 and L2 into the datapath. On a **cache miss**, the pipeline is held in stall until the requested word arrives from DMEM and is written into the cache.

#### L1 Cache (`L1_cache.sv`)

| Parameter | Value |
|---|---|
| Organization | 64 sets × 2 ways |
| Address decomposition | Tag [31:8] · Index [7:2] · Offset [1:0] |
| Replacement policy | LRU (per-set 1-bit LRU bit) |
| Word size | 32 bits |
| Miss handling | FSM (MAIN → WAIT\_WRITE) |

`cache_hit` encoding:
- `2'b10` → Hit
- `2'b01` → Miss
- `2'b00` → Idle

#### L2 Cache (`L2_cache.sv`)

| Parameter | Value |
|---|---|
| Organization | 64 sets × 4 ways |
| Address decomposition | Tag [31:8] · Index [7:2] · Offset [1:0] |
| Replacement policy | MRU (2-bit MRU pointer per set) |
| Word size | 32 bits |

On an L2 miss, the address and a write-enable signal (`we_dmem`) are issued to DMEM. Once DMEM responds with valid data (`valid_mem`), L2 fills the line and signals L1 via `valid_data_from_L2`.

---

## Project Structure

```
.
├── constraint/
│   └── clock_constraint.xdc      # Vivado timing constraint (200 ns clock)
├── hdl/
│   ├── TOP.sv                    # Top-level: pipeline + caches + memories
│   ├── riscVpipeline.sv          # Pipeline top (datapath + controller)
│   ├── datapath.sv               # All pipeline registers and datapath logic
│   ├── controller.sv             # Control unit (propagates signals across stages)
│   ├── hazard_unit.sv            # Forwarding, stall and flush logic
│   ├── alu.sv                    # ALU
│   ├── aludec.sv                 # ALU decoder
│   ├── maindec.sv                # Main decoder
│   ├── extend.sv                 # Immediate sign-extension
│   ├── adder.sv                  # PC adder
│   ├── regfile.sv                # 32×32 register file
│   ├── imem.sv                   # Instruction memory (ROM)
│   ├── dmem.sv                   # Data memory (RAM)
│   ├── cache_subsystem.sv        # L1 + L2 integration wrapper
│   ├── L1_cache.sv               # L1 cache (64-set, 2-way, LRU)
│   └── L2_cache.sv               # L2 cache (64-set, 4-way, MRU)
├── tb/
│   ├── pipeline_tb.sv            # Top-level pipeline testbench
│   ├── cache_L1_tb.sv            # L1 cache unit testbench
│   ├── cache_L2_tb.sv            # L2 cache unit testbench
│   └── cache_subsystem_tb.sv     # Integrated cache subsystem testbench
├── instruction/
│   └── test.txt                  # Assembly test programs with hex encodings
├── images/
│   ├── l1_hit_logic.png          # L1 cache hit logic diagram
│   ├── l2_hit_logic.png          # L2 cache hit logic diagram
│   └── *.PNG                     # Waveform screenshots per instruction type
├── scripts/
│   └── create_project_vivado.tcl # Automated Vivado project creation script
├── tb_behav.wcfg                 # Vivado waveform configuration
└── NMS-projekat.pdf              # Project report (design documentation)
```

---

## Supported Instructions

| Type | Instructions |
|---|---|
| **R** | `add`, `sub`, `xor`, `or`, `and`, `sll`, `srl`, `slt` |
| **I** | `addi`, `xori`, `ori`, `andi`, `slli`, `srli`, `slti`, `lw` |
| **B** | `beq`, `bne`, `blt`, `bge` |
| **J** | `jal` |

Test programs for all instruction types are available in `instruction/test.txt`, along with pre-encoded RAM initialisation values ready to paste into `imem.sv`.

---

## Getting Started

### Prerequisites

- **Xilinx Vivado** 2020.1 or later (for synthesis and simulation)
- Target board: **Digilent Zybo Z7-20** (`xc7z020clg400-1`)
- Alternatively, any Vivado-supported Zynq-7000 or 7-series board (adjust the part in the TCL script)

### Creating the Vivado Project

From the Vivado Tcl console, run:

```tcl
source ./scripts/create_project_vivado.tcl
```

This script automatically:
1. Creates a new Vivado project under `../vivado_project/`
2. Sets the target board to Zybo Z7-20
3. Adds all HDL source files and testbenches
4. Applies the clock constraint

### Running Simulation

1. Open the generated Vivado project.
2. In the **Flow Navigator**, select **Run Simulation → Run Behavioral Simulation**.
3. Load `tb_behav.wcfg` to restore the pre-configured waveform view.
4. The top-level testbench (`pipeline_tb.sv`) instantiates `TOP`, applies reset for 800 ns, then runs for 20 µs.

To test individual cache components, set the simulation source to one of:
- `tb/cache_L1_tb.sv`
- `tb/cache_L2_tb.sv`
- `tb/cache_subsystem_tb.sv`

---

## Constraints

The design is clocked at **5 MHz** (200 ns period), defined in `constraint/clock_constraint.xdc`:

```tcl
create_clock -period 200 -name clk -waveform {0.000 100.000} [get_ports clk]
```

---

## Testing

Simulation waveforms for each instruction type are included under `images/` and were cross-validated against the **RIPES** RISC-V simulator:

| Test | Waveform | RIPES reference |
|---|---|---|
| R-type | `R-test-instructions.PNG` | `R-test-instructions-ripes.PNG` |
| I-type | `I-test-instructions.PNG` | `I-test-instructions-ripes.PNG` |
| B-type (branch taken) | `B-test-instructions-with-branch.PNG` | `B-test-instructions-with-branch-ripes.PNG` |
| B-type (branch not taken) | `B-test-instructions-without-branch.PNG` | `B-test-instructions-without-branch-ripes.PNG` |
| J-type | `J-test-instructions.PNG` | `J-test-instructions-ripes.PNG` |
| LW from DMEM (addr 0) | `lw-from-dmem-address-ZERO.png` | `lw-from-dmem-address-ZERO-ripes.PNG` |
| LW from DMEM (addr 3) | `lw-from-dmem-address-THREE.png` | `lw-from-dmem-address-THREE-ripes.PNG` |
| LW from DMEM (addr 5) | `lw-from-dmem-address-FIVE.png` | `lw-from-dmem-address-FIVE-ripes.PNG` |

Cache hit logic diagrams are available in `images/l1_hit_logic.png` and `images/l2_hit_logic.png`.

For a full description of the design decisions, architecture diagrams and test results, see **NMS-projekat.pdf**.
