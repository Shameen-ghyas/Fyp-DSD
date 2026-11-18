import numpy as np

from fixed_ref import hexs
from conv_ref import conv1d_layer

rng = np.random.default_rng(3)

T, N = 64, 16

# (output channels, kernel size, dilation, shift, relu)
CFGS = [
    (16, 3, 1, 10, 1),
    (8, 3, 2, 10, 0),
    (16, 1, 1, 9, 1),
    (12, 3, 4, 10, 1)
]

rom = []
brom = []
cfg_lines = []

wbase = 0
bbase = 0

for i, (co, k, d, sh, relu) in enumerate(CFGS):

    # Generate input activations
    x = rng.integers(-128, 128, (T, N))

    mask = rng.random((T, N)) < 0.1
    x[mask] = rng.choice([-128, 127], mask.sum())

    # Generate weights and biases
    w = rng.integers(-128, 128, (co, k, N))
    b = rng.integers(-2000, 2000, co)

    # Calculate expected output
    y = conv1d_layer(x, w, [int(v) for v in b], d, sh, relu)

    # Convert each row into hexadecimal
    # Channel 0 is stored in the lowest byte
    def rowhex(r):
        result = ""

        for v in reversed(list(r)):
            result += hexs(v, 8)

        return result

    # Save activation data
    with open(f"../vectors/conv_act_{i}.mem", "w") as f:
        for r in x:
            f.write(rowhex(r) + "\n")

    # Save expected output
    with open(f"../vectors/conv_exp_{i}.mem", "w") as f:
        for r in y:
            f.write(rowhex(r) + "\n")

    # Save weights
    for c in range(co):
        for kk in range(k):
            rom.append(rowhex(w[c, kk]))

    # Save biases
    for v in b:
        brom.append(hexs(int(v), 32))

    # Save configuration
    cfg = (co, k, d, sh, relu, wbase, bbase)

    cfg_line = ""
    for v in cfg:
        cfg_line += hexs(v, 16)

    cfg_lines.append(cfg_line)

    # Update ROM base addresses
    wbase += co * k
    bbase += co


# Write weight ROM
with open("../vectors/conv_wrom.mem", "w") as f:
    f.write("\n".join(rom) + "\n")

# Write bias ROM
with open("../vectors/conv_brom.mem", "w") as f:
    f.write("\n".join(brom) + "\n")

# Write configurations
with open("../vectors/conv_cfg.mem", "w") as f:
    f.write("\n".join(cfg_lines) + "\n")


print(
    "conv configs:", len(CFGS),
    "weight rows:", len(rom),
    "bias words:", len(brom)
)