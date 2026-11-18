import math

# Fixed-point data limits
DATA_MIN = -128
DATA_MAX = 127

# Number of channels and phase period
NCH = 7
PERIOD = 200
STALE_MAX = 127


# Convert a number into signed 32-bit range
def wrap32(x):
    x = int(x) & 0xFFFFFFFF

    if x & 0x80000000:
        return x - (1 << 32)

    return x


# Keep a number within signed 8-bit range
def sat8(x):
    return max(DATA_MIN, min(DATA_MAX, int(x)))


# Round a number and shift it right
def round_shift(x, shift):
    if shift == 0:
        return int(x)

    x = wrap32(int(x) + (1 << (shift - 1)))
    return x >> shift


# Convert accumulator value into signed 8-bit output
def requantize(acc, bias, shift, relu=False):
    v = wrap32(acc + bias)
    v = round_shift(v, shift)
    v = sat8(v)

    if relu and v < 0:
        v = 0

    return v


# Multiply corresponding values and accumulate results
def mac(a_vec, b_vec, acc0=0):
    acc = acc0

    for a, b in zip(a_vec, b_vec):
        acc = wrap32(acc + int(a) * int(b))

    return acc


# Convert a signed number into hexadecimal format
def hexs(x, bits):
    mask = (1 << bits) - 1
    return format(int(x) & mask, "0{}x".format(bits // 4))


# Generate preprocessing parameters
def scale_sample(x, median, mult, shift):
    diff = int(x) - int(median)
    prod = diff * int(mult)

    return requantize(prod, 0, shift, False)


# Generate sine and cosine lookup table values
def phase_tables(period=PERIOD):
    s = []
    c = []

    for k in range(period):
        angle = 2 * math.pi * k / period

        sin_value = int(round(127 * math.sin(angle)))
        cos_value = int(round(127 * math.cos(angle)))

        s.append(sin_value)
        c.append(cos_value)

    return s, c


# Update the staleness counter
def stale_step(prev, fresh):
    if fresh:
        return 0

    return min(prev + 1, STALE_MAX)