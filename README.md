# Asynchronous FIFO — RTL + SVA + UVM Verification

Production-quality async FIFO with full UVM verification environment. Implements the Cummings SNUG 2002 Gray-code pointer architecture for safe clock domain crossing.

## Architecture

```
                    wclk domain                              rclk domain
               ┌──────────────────┐                    ┌──────────────────┐
               │                  │                    │                  │
  winc ───────►│   wptr_full      │    Gray ptr        │   rptr_empty     │◄─────── rinc
  wdata ──┐    │  (bin counter,   │───────────────────►│  (bin counter,   │
          │    │   Gray encode,   │    2-FF sync       │   Gray encode,   │
          │    │   full flag)     │◄───────────────────│   empty flag)    │
          │    └──────────────────┘    Gray ptr         └──────────────────┘
          │             │                                        │
          │          waddr                                    raddr
          │             │                                        │
          │    ┌────────▼────────────────────────────────────────▼────────┐
          └───►│                  dual_port_ram                          │──────► rdata
               │           (registered read output)                      │
               └─────────────────────────────────────────────────────────┘
```

## Key Design Decisions

**Gray-code pointers**: Only 1 bit changes per clock cycle, eliminating metastability-induced multi-bit errors during CDC synchronization.

**2-FF synchronizer**: Meets MTBF requirements for typical process nodes. Adds 2 cycles of latency per direction, making full/empty flags *conservative* — they may briefly indicate full (or empty) when not truly so, but never the reverse. This is safe: false-full causes backpressure (not data loss), false-empty causes stall (not corruption).

**Registered RAM output**: Improves timing closure on the read path at the cost of 1 cycle read latency. The read monitor compensates for this.

**Full detection**: `wgray_next == {~rptr_sync[MSB:MSB-1], rptr_sync[MSB-2:0]}` — the top 2 bits are inverted because the write pointer has wrapped once more than the read pointer.

**Empty detection**: `rgray_next == wptr_sync` — Gray pointers match exactly means same address and same wrap count.

## Directory Structure

```
async_fifo/
├── rtl/
│   ├── async_fifo_pkg.sv      # Shared types, bin2gray/gray2bin
│   ├── async_fifo.sv          # Top-level module
│   ├── dual_port_ram.sv       # True dual-port RAM (1W/1R)
│   ├── sync_2ff.sv            # 2-flop synchronizer
│   ├── wptr_full.sv           # Write pointer + full generation
│   ├── rptr_empty.sv          # Read pointer + empty generation
│   └── async_fifo_sva.sv      # SVA assertions (bind module)
├── tb/
│   ├── async_fifo_if.sv       # Virtual interface + clocking blocks
│   ├── async_fifo_tb_pkg.sv   # Package (compile order for includes)
│   ├── async_fifo_seq_item.sv # Transaction object
│   ├── async_fifo_wr_driver.sv
│   ├── async_fifo_rd_driver.sv
│   ├── async_fifo_wr_monitor.sv
│   ├── async_fifo_rd_monitor.sv
│   ├── async_fifo_scoreboard.sv   # Reference model + FIFO checker
│   ├── async_fifo_coverage.sv     # Covergroups (data, flags, fill-level, transitions)
│   ├── async_fifo_wr_agent.sv
│   ├── async_fifo_rd_agent.sv
│   ├── async_fifo_env.sv
│   ├── async_fifo_sequences.sv    # 5 sequences (base, burst, incremental)
│   ├── async_fifo_base_test.sv    # Base test + 3 derived tests
│   └── tb_top.sv                  # Top-level harness, clock gen, bind
└── sim/
    ├── Makefile               # VCS / Xcelium / Questa targets
    └── filelist.f             # Compilation file list
```

## UVM Testbench Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      uvm_test                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │                   async_fifo_env                   │  │
│  │  ┌─────────────┐   ┌─────────────┐               │  │
│  │  │  wr_agent    │   │  rd_agent    │               │  │
│  │  │ ┌─────────┐ │   │ ┌─────────┐ │               │  │
│  │  │ │sequencer│ │   │ │sequencer│ │               │  │
│  │  │ │ driver  │ │   │ │ driver  │ │               │  │
│  │  │ │ monitor─┼─┼───┼─┼─monitor─┼─┼──┐            │  │
│  │  │ └─────────┘ │   │ └─────────┘ │  │            │  │
│  │  └─────────────┘   └─────────────┘  │            │  │
│  │          │                  │        │            │  │
│  │          ▼                  ▼        ▼            │  │
│  │  ┌──────────────┐  ┌──────────────────────────┐  │  │
│  │  │  scoreboard  │  │  coverage (wr_cov/rd_cov)│  │  │
│  │  │ (ref queue + │  │  (covergroups: data,     │  │  │
│  │  │  pending_rd) │  │   flags, fill, xitions)  │  │  │
│  │  └──────────────┘  └──────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## SVA Assertions

| ID | Domain | Property | What it catches |
|----|--------|----------|-----------------|
| W1 | wclk | No pointer advance when full | Overflow |
| W2 | wclk | Full clears after synced rptr changes | CDC liveness |
| W3 | wclk | Not full after reset | Reset bug |
| W4 | wclk | Gray pointer single-bit change | Encoding bug |
| R1 | rclk | No pointer advance when empty | Underflow |
| R2 | rclk | Empty after reset | Reset bug |
| R3 | rclk | Gray pointer single-bit change | Encoding bug |
| R4 | rclk | Empty clears after synced wptr changes | CDC liveness |
| F1 | wclk | RAM wen gated when full | Overflow corruption |
| F2 | rclk | RAM ren gated when empty | Underflow garbage |
| F3 | wclk | Write pointer monotonic | Counter bug |
| F4 | rclk | Read pointer monotonic | Counter bug |

Plus 8 cover properties targeting full, empty, transitions, burst fill, and drain scenarios.

## Tests

| Test | Scenario | What it exercises |
|------|----------|-------------------|
| `async_fifo_simple_test` | Sequential write-then-read | Basic data integrity, FIFO ordering |
| `async_fifo_concurrent_test` | Parallel write + read (fork-join) | CDC stress, concurrent pointer updates |
| `async_fifo_overflow_test` | Burst write past capacity + burst read past content | Overflow/underflow protection |

## Running

```bash
cd sim/

# VCS
make vcs TEST=async_fifo_simple_test
make vcs TEST=async_fifo_concurrent_test
make vcs TEST=async_fifo_overflow_test

# Xcelium
make xrun TEST=async_fifo_concurrent_test

# Questa
make questa TEST=async_fifo_overflow_test

# Clean
make clean
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 8 | Data bus width in bits |
| `ADDR_WIDTH` | 3 | Address width; FIFO depth = 2^ADDR_WIDTH |

## Design Tradeoffs Worth Discussing

1. **Conservative flags vs. exact count**: This design trades throughput for safety. The 2-FF sync delay means the write side sees a stale read pointer, so `wfull` asserts 2 read-cycles early. An almost-full/almost-empty threshold counter could mitigate this at the cost of more logic.

2. **Registered vs. combinational RAM read**: Registered output adds 1 cycle latency but closes timing at higher frequencies. For shallow FIFOs or low-frequency designs, a combinational read (`assign rdata = mem[raddr]`) saves a cycle.

3. **Async reset strategy**: Each domain has its own async reset. Reset deassertion should be synchronized to the respective clock (not done here — a reset synchronizer would be added in production).

4. **Scoreboard pending_rd buffer**: Cross-domain monitors can deliver transactions to the scoreboard out of order due to simulator event scheduling. The pending_rd queue absorbs reads that arrive before their corresponding write, draining when writes catch up.

## References

- Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design", SNUG 2002
- Cummings, "Synthesis and Scripting Techniques for Designing Multi-Asynchronous Clock Designs", SNUG 2001
