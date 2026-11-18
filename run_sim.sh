#!/bin/bash
# run_sim.sh -- builds and tests ONLY the TCN-core task modules:
#   window_buffer, conv1d_engine, residual_add, upsample_unit, downsample_unit, encdec_top_tcn
# Usage (from the project folder):  ./run_sim.sh      Needs: iverilog, python3, numpy
cd "$(dirname "$0")"
mkdir -p sim vectors

# 1) regenerate golden vectors (.mem files) from the Python reference
GENS="gen_vectors.py gen_conv_vectors.py gen_rowops_vectors.py gen_tcn_vectors.py"
for g in $GENS; do
  (cd python && python3 $g) || { echo "VECTOR GENERATION FAILED: $g"; exit 1; }
done

# 2) RTL files (package first). Extra files in rtl/ are NOT compiled.
RTL="rtl/fixed_pkg.sv rtl/mac_unit.sv rtl/mac_array.sv rtl/requantize.sv rtl/dp_ram.sv rtl/weight_rom.sv \
     rtl/window_buffer.sv rtl/conv1d_engine.sv rtl/residual_add.sv rtl/upsample_unit.sv rtl/downsample_unit.sv rtl/encdec_top_tcn.sv"

# 3) testbenches
TBS="tb_requantize tb_mac_unit tb_mac_array tb_window_buffer tb_conv1d_engine tb_rowops tb_encdec_top_tcn"

fails=0
for tb in $TBS; do
  iverilog -g2012 -s $tb -o sim/$tb.vvp $RTL tb/$tb.sv || { echo "$tb: COMPILE FAIL"; fails=$((fails+1)); continue; }
  out=$(timeout 250 vvp -n sim/$tb.vvp 2>&1 | grep -v readmemh)
  echo "$out" | grep -E "PASS|FAIL|cycles|got|bad|timeout|missing|early|lane|MISMATCH"
  echo "$out" | grep -q "PASS" || { echo "$tb: no PASS line (hang or error)"; fails=$((fails+1)); }
  echo "$out" | grep -q "FAIL" && fails=$((fails+1))
done
if [ $fails -eq 0 ]; then echo "=== ALL TESTBENCHES PASS ==="; else echo "=== $fails FAILURE(S) ==="; fi