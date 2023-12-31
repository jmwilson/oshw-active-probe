import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import math

from matplotlib.ticker import EngFormatter

Z0 = 50

# Quick and dirty Touchstone file reader for S1P
def read_s1p_file(fd):
    lines = filter(lambda s: not s.startswith('!') and not s.isspace(), fd.readlines())
    option_line, *data = lines
    if not option_line.startswith("#"):
        raise ValueError('Invalid Touchstone file')
    freq_unit, parameter, fmt, _, Z0 = option_line.lstrip(
        '#').casefold().split()
    if freq_unit == 'hz':
        freq_exp = 1
    elif freq_unit == 'khz':
        freq_exp = 1e3
    elif freq_unit == 'mhz':
        freq_exp = 1e6
    elif freq_unit == 'ghz':
        freq_exp = 1e9
    else:
        raise ValueError('Invalid frequency unit in Touchstone file')
    if not(parameter == 's' and fmt == 'ri'):
        raise ValueError('Unexpected Touchstone format, bailing...')
    mat = np.array([list(map(float, l.split())) for l in data])
    freq = freq_exp * mat[:,0]
    s11 = mat[:,1] + 1j * mat[:,2]
    return freq, s11

data = pd.read_csv("Dataset_20231117145831.csv", skiprows=50, header=None)
with open("Dataset_20231117152043.s1p") as fd:
    freq, s11 = read_s1p_file(fd)

with open("Dataset_20231117143316.s1p") as fd:
    _,s11_line = read_s1p_file(fd)

z_data = Z0 * (1 + s11) / (1 - s11)
z_line = Z0 * (1 + s11_line) / (1 - s11_line)

z_probe = 1/(1/z_data - 1/z_line)

plt.figure(figsize=(10,6))
ax = plt.axes()
plt.plot(data[0], data[1])
#plt.plot(data[4], data[5])
#plt.plot(data[8], data[9])
plt.xscale('log')
plt.xlabel('Frequency')
ax.xaxis.set_major_formatter(EngFormatter(unit='Hz'))
plt.yscale('linear')
plt.ylabel('$|S_{21}|$ (dB)')
plt.grid(axis='both', which='both')

plt.title('Active probe proto 1')
plt.tight_layout()
plt.savefig("probe_s21.svg", format='svg')

plt.figure(figsize=(10,6))
ax = plt.axes()
plt.plot(freq, abs(z_probe))
plt.xscale('log')
plt.xlabel('Frequency')
ax.xaxis.set_major_formatter(EngFormatter(unit='Hz'))
plt.yscale('log')
plt.ylabel('Impedance')
ax.yaxis.set_major_formatter(EngFormatter(unit='Ω'))
plt.grid(axis='both', which='both')

plt.title('Active probe proto 1 input impedance')
plt.tight_layout()
plt.savefig("probe_input_impedance.svg", format='svg')


plt.show()
