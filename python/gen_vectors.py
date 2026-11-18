import numpy as np

from fixed_ref import requantize, hexs, mac


# Use a fixed random seed 
rng = np.random.default_rng(1)

# PART 1: GENERATE REQUANTIZE TEST VECTORS

rows = [
    (0, 0, 0),
    (127, 0, 0),
    (-128, 0, 0),
    (1000, 0, 2),
    (-1000, 0, 2),
    (2, 0, 2),
    (6, 0, 2),
    (-2, 0, 2),
    (2**31 - 1, 0, 0),
    (-2**31, 0, 0),
    (2**31 - 1, 5, 3),
    (12345, -12345, 4),
    (1 << 20, 0, 12),
    (-(1 << 20), 0, 12)
]


# Add 2000 random test cases.
for i in range(2000):

    acc = int(rng.integers(-2**22, 2**22))
    bias = int(rng.integers(-2**12, 2**12))
    shift = int(rng.integers(0, 16))

    rows.append((acc, bias, shift))


# Create the requantization memory file.
vector_count = 0

with open("../vectors/requant_vec.mem", "w") as file:

    for acc, bias, shift in rows:

        # Test both ReLU settings.
        for relu in (0, 1):

            # Calculate expected output using Python reference.
            expected = requantize(acc, bias, shift, bool(relu))

            # Convert each field to hexadecimal.
            acc_hex = hexs(acc, 32)
            bias_hex = hexs(bias, 32)
            shift_hex = hexs(shift, 8)
            relu_hex = hexs(relu, 8)
            expected_hex = hexs(expected, 8)

            # Combine all fields into one 88-bit vector.
            line = (
                acc_hex
                + bias_hex
                + shift_hex
                + relu_hex
                + expected_hex
            )

            file.write(line + "\n")

            vector_count += 1


print("requant vectors:", vector_count)

# PART 2: GENERATE MAC TEST VECTORS

vector_count = 0

with open("../vectors/mac_vec.mem", "w") as file:

    for k in range(500):

        # Generate two arrays of 16 random INT8 values.
        a = rng.integers(-128, 128, 16)
        b = rng.integers(-128, 128, 16)

        # Replace the first three cases with extreme values.
        if k < 3:

            if k == 0:
                b_value = -128

            elif k == 1:
                b_value = 127

            else:
                b_value = 0

            for i in range(16):
                a[i] = -128
                b[i] = b_value

        # Calculate expected MAC result.
        expected = mac(a, b)

        # Convert all 16 elements of array a to hexadecimal.
        a_hex = ""
        for value in a:
            a_hex += hexs(value, 8)

        # Convert all 16 elements of array b to hexadecimal.
        b_hex = ""
        for value in b:
            b_hex += hexs(value, 8)

        # Convert expected result to hexadecimal.
        expected_hex = hexs(expected, 32)

        # Combine all fields into one line.
        line = a_hex + b_hex + expected_hex

        file.write(line + "\n")

        vector_count += 1


print("mac vectors:", vector_count)
