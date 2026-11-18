"""Compile and run the self-checking benches with Icarus Verilog."""

import argparse
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SIM = Path("sim")
BUILD = Path("build/sim")


def main():
    benches = {
        path.stem[3:]: path.relative_to(ROOT)
        for path in sorted((ROOT / SIM).glob("tb_*.sv"))
    }
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cases", nargs="*", metavar="CASE",
                        help=f"select cases from {', '.join(benches)}")
    parser.add_argument("--vcd", action="store_true", help="save waves in build/sim")
    args = parser.parse_args()

    cases = args.cases or list(benches)
    for case in cases:
        if case not in benches:
            parser.error(f"unknown case {case!r}. See --help for available cases.")

    iverilog = shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if not iverilog or not vvp:
        parser.exit(1, "Install Icarus Verilog and put iverilog and vvp on PATH.\n")

    rtl = [str(file.relative_to(ROOT)) for file in sorted((ROOT / "rtl").glob("*/*.v"))]
    (ROOT / BUILD).mkdir(parents=True, exist_ok=True)

    for case in cases:
        bench = benches[case]
        program = BUILD / f"{bench.stem}.vvp"
        print(f"== {case} ==", flush=True)
        try:
            subprocess.run(
                [iverilog, "-g2012", "-Wall", "-s", bench.stem, "-o", str(program),
                 *rtl, str(SIM / "uart_test_link.sv"), str(bench)],
                cwd=ROOT, check=True, timeout=60,
            )
            args_for_vvp = [vvp, "-N", program.name]
            if args.vcd:
                args_for_vvp.append("+vcd")
            subprocess.run(args_for_vvp, cwd=ROOT / BUILD, check=True, timeout=60)
        except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
            parser.exit(1, f"{case} failed: {error}\n")

    print(f"Passed {len(cases)} simulations.")


if __name__ == "__main__":
    main()
