import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import math

from matplotlib.ticker import EngFormatter

Z0 = 50
c0 = 299792458

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

def X_C(freq, C):
    return 1/(2*math.pi*C*freq)

data = pd.read_csv("probe_insertionloss.csv", skiprows=51, header=None)
with open("probed_line_returnloss.s1p") as fd:
    freq, s11_probed_line = read_s1p_file(fd)

with open("line_returnloss.s1p") as fd:
    _,s11_line = read_s1p_file(fd)

# add a port extension to account for measured electrical length from calibration plane to board edge of exposed line
meas_plane_shift = 14.839e-3
port_extension = np.exp(1j*2*meas_plane_shift*2*np.pi/c0*freq)
s11_probed_line = port_extension * s11_probed_line
s11_line = port_extension * s11_line

z_probed_line = Z0 * (1 + s11_probed_line) / (1 - s11_probed_line)
z_line = Z0 * (1 + s11_line) / (1 - s11_line)
z_probe_only = 1/(1/z_probed_line - 1/z_line)
min_freq_index = (freq >= 1e8).argmax()

plt.figure(figsize=(10,6))
ax = plt.axes()
plt.plot(data[0], data[1])
plt.xscale('log')
plt.xlabel('Frequency')
ax.xaxis.set_major_formatter(EngFormatter(unit='Hz'))
plt.yscale('linear')
plt.ylabel('$|S_{21}|$ (dB)')
plt.grid(axis='both', which='both')

plt.title('Probe insertion loss')
plt.tight_layout()
plt.savefig("probe_s21.svg", format='svg')

plt.figure(figsize=(10,6))
ax = plt.axes()
plt.plot(freq[min_freq_index:], abs(z_probe_only[min_freq_index:]))
trend_freq = np.logspace(8, 9, 20)
plt.plot(trend_freq, X_C(trend_freq, 1e-12))
ax.annotate("1 pF", xy=(800e6, X_C(800e6, 1e-12)), xycoords='data', xytext=(50,30), textcoords='offset points', arrowprops=dict(arrowstyle='->', facecolor='black'))
plt.xscale('log')
plt.xlabel('Frequency')
ax.xaxis.set_major_formatter(EngFormatter(unit='Hz'))
plt.yscale('log')
plt.ylabel('Impedance')
ax.yaxis.set_major_formatter(EngFormatter(unit='Ω'))
plt.grid(axis='both', which='both')

plt.title('Probe input impedance')
plt.tight_layout()
plt.savefig("probe_z.svg", format='svg')


plt.show()
