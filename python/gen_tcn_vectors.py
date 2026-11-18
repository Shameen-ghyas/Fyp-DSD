"""Builds the whole TCN autoencoder reference + all .mem files for encdec_top_tcn.
Network (T=64, 16 channels, row = 16 bytes):
  L0 conv(16->16,k3,d1,relu) -> A | L1 pool x2 -> B | L2 conv(16->8,k3,d2,relu) -> A | L3 upsample x2 -> B
  L4 conv(8->16,k3,d1,relu) -> A (=H) | L5 conv(16->16,k3,d1) -> C (=G) | L6 residual H+G -> B  (output)
Buffers: 0=IN 1=A 2=B 3=C. Op codes: 0=CONV 1=POOL 2=UP 3=ADD."""
import numpy as np
from fixed_ref import hexs
from conv_ref import conv1d_layer
from rowops_ref import residual, upsample, downsample
rng = np.random.default_rng(11)
T, N = 64, 16
rowhex = lambda r: "".join(hexs(v, 8) for v in reversed(list(r)))

# (c_out, k, dil, shift, relu)
CONV = {0: (16, 3, 1, 7, 1), 1: (8, 3, 2, 6, 1), 2: (16, 3, 1, 6, 1), 3: (16, 3, 1, 6, 0)}
W, B = {}, {}
for i, (co, k, d, sh, relu) in CONV.items():
    W[i] = rng.integers(-20, 21, (co, k, N)); B[i] = rng.integers(-200, 200, co)
W[2][:, :, 8:] = 0                                   # layer-2 input only has 8 real channels

x = rng.integers(-100, 100, (T, N))
c = lambda i, a: conv1d_layer(a, W[i], [int(v) for v in B[i]], CONV[i][2], CONV[i][3], CONV[i][4])
a0 = c(0, x); p = downsample(a0); a1 = c(1, p); u = upsample(a1); h = c(2, u); g = c(3, h); y = residual(h, g, False)
ya = np.array(y); print("output: nonzero %.0f%%, saturated %.1f%%" % (100*(ya != 0).mean(), 100*((ya == 127) | (ya == -128)).mean()))

# weight / bias ROMs and descriptor table
rom, brom, wbase, bbase = [], [], {}, {}
for i, (co, k, *_ ) in CONV.items():
    wbase[i], bbase[i] = len(rom), len(brom)
    rom += [rowhex(W[i][cc, kk]) for cc in range(co) for kk in range(k)]
    brom += [hexs(int(v), 32) for v in B[i]]
def desc(op, src, src2, dst, n_t, conv=None):
    co, k, d, sh, relu, wb, bb = (0, 0, 0, 0, 0, 0, 0) if conv is None else (*CONV[conv], wbase[conv], bbase[conv])
    v = op | src << 3 | src2 << 5 | dst << 7 | n_t << 9 | co << 17 | k << 22 | d << 26 | sh << 31 | relu << 36 | wb << 37 | bb << 45
    return hexs(v, 64)
D = [desc(0, 0, 0, 1, 64, 0), desc(1, 1, 0, 2, 32), desc(0, 2, 0, 1, 32, 1), desc(2, 1, 0, 2, 32),
     desc(0, 2, 0, 1, 64, 2), desc(0, 1, 0, 3, 64, 3), desc(3, 1, 3, 2, 64)]
w = lambda name, lines: open(f"../vectors/{name}.mem", "w").write("\n".join(lines) + "\n")
w("tcn_wrom", rom); w("tcn_brom", brom); w("tcn_desc", D)
w("tcn_in", [rowhex(r) for r in x]); w("tcn_exp", [rowhex(r) for r in y])
print("tcn: %d weight rows, %d bias words, %d layers" % (len(rom), len(brom), len(D)))
