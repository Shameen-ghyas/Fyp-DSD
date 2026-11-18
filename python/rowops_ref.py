from fixed_ref import sat8


def residual(a, b, relu):
    out = []

    for ra, rb in zip(a, b):

        row = []

        for x, y in zip(ra, rb):
            row.append(sat8(int(x) + int(y)))

        if relu:
            row = [max(v, 0) for v in row]

        out.append(row)

    return out


def upsample(x):
    out = []

    for r in x:
        out.append(list(r))
        out.append(list(r))

    return out


def downsample(x):
    out = []

    for t in range(len(x) // 2):

        row = []

        for a, b in zip(x[2*t], x[2*t+1]):
            row.append((int(a) + int(b) + 1) >> 1)

        out.append(row)

    return out