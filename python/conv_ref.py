"""Bit-accurate reference for conv1d_engine.
Tap k reads x[t - k*dil] with causal zero padding.
"""

from fixed_ref import requantize, wrap32


def conv1d_layer(x, w, bias, dil, shift, relu):

    T = len(x)
    N = len(x[0])

    C_OUT = len(w)
    K = len(w[0])

    # Initialize output with zeros
    y = [[0] * N for _ in range(T)]

    for t in range(T):
        for co in range(C_OUT):

            acc = 0

            for k in range(K):

                s = t - k * dil

                if s >= 0:
                    for ci in range(N):

                        acc = wrap32(
                            acc + x[s][ci] * w[co][k][ci]
                        )

            y[t][co] = requantize(acc, bias[co], shift, relu)

    return y