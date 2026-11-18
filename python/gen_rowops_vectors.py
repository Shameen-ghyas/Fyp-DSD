import numpy as np

from fixed_ref import hexs
from rowops_ref import residual, upsample, downsample

rng = np.random.default_rng(5)

T, N = 64, 16


def mk():
    x = rng.integers(-128, 128, (T, N))

    mask = rng.random((T, N)) < 0.15
    x[mask] = rng.choice([-128, 127], mask.sum())

    return x


def rowhex(row):
    result = ""

    for value in reversed(list(row)):
        result += hexs(value, 8)

    return result


def dump(name, rows):
    with open(f"../vectors/{name}.mem", "w") as f:
        for row in rows:
            f.write(rowhex(row) + "\n")


a = mk()
b = mk()

dump("rowops_a", a)
dump("rowops_b", b)

dump("rowops_res", residual(a, b, False))
dump("rowops_res_relu", residual(a, b, True))

dump("rowops_up", upsample(a[:T//2]))
dump("rowops_down", downsample(a))

print("rowops vectors ok")