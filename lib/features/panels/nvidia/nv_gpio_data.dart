// Tegra234 (AGX Orin) GPIO port -> index maps, from
// dt-bindings/gpio/tegra234-gpio.h. Used to compute the gpioset/gpioget
// line offset: offset = portIndex * 8 + pin.

/// Main controller (gpiochip0, label tegra234-gpio).
const Map<String, int> kTegraMainPorts = {
  'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5, 'G': 6, 'H': 7, 'I': 8,
  'J': 9, 'K': 10, 'L': 11, 'M': 12, 'N': 13, 'P': 14, 'Q': 15, 'R': 16,
  'S': 17, 'T': 18, 'U': 19, 'V': 20, 'W': 21, 'X': 22, 'Y': 23, 'Z': 24,
  'AC': 25, 'AD': 26, 'AE': 27, 'AF': 28, 'AG': 29,
};

/// AON controller (gpiochip1, label tegra234-gpio-aon).
const Map<String, int> kTegraAonPorts = {
  'AA': 0, 'BB': 1, 'CC': 2, 'DD': 3, 'EE': 4, 'GG': 5,
};
