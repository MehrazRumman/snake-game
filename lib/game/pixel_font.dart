/// A tiny 5 px tall bitmap font in the spirit of old monochrome phone
/// screens. Most glyphs are 3 px wide; M, N and W need more room to stay
/// legible. 'X' is a lit pixel.
const int glyphHeight = 5;
const int glyphSpacing = 1;

const Map<String, List<String>> glyphs = {
  '0': ['XXX', 'X.X', 'X.X', 'X.X', 'XXX'],
  '1': ['.X.', 'XX.', '.X.', '.X.', 'XXX'],
  '2': ['XXX', '..X', 'XXX', 'X..', 'XXX'],
  '3': ['XXX', '..X', '.XX', '..X', 'XXX'],
  '4': ['X.X', 'X.X', 'XXX', '..X', '..X'],
  '5': ['XXX', 'X..', 'XXX', '..X', 'XXX'],
  '6': ['XXX', 'X..', 'XXX', 'X.X', 'XXX'],
  '7': ['XXX', '..X', '.X.', '.X.', '.X.'],
  '8': ['XXX', 'X.X', 'XXX', 'X.X', 'XXX'],
  '9': ['XXX', 'X.X', 'XXX', '..X', 'XXX'],
  'A': ['.X.', 'X.X', 'XXX', 'X.X', 'X.X'],
  'B': ['XX.', 'X.X', 'XX.', 'X.X', 'XX.'],
  'C': ['.XX', 'X..', 'X..', 'X..', '.XX'],
  'D': ['XX.', 'X.X', 'X.X', 'X.X', 'XX.'],
  'E': ['XXX', 'X..', 'XX.', 'X..', 'XXX'],
  'F': ['XXX', 'X..', 'XX.', 'X..', 'X..'],
  'G': ['.XX', 'X..', 'X.X', 'X.X', '.XX'],
  'H': ['X.X', 'X.X', 'XXX', 'X.X', 'X.X'],
  'I': ['XXX', '.X.', '.X.', '.X.', 'XXX'],
  'J': ['..X', '..X', '..X', 'X.X', '.X.'],
  'K': ['X.X', 'X.X', 'XX.', 'X.X', 'X.X'],
  'L': ['X..', 'X..', 'X..', 'X..', 'XXX'],
  'M': ['X...X', 'XX.XX', 'X.X.X', 'X...X', 'X...X'],
  'N': ['X..X', 'XX.X', 'X.XX', 'X..X', 'X..X'],
  'O': ['.X.', 'X.X', 'X.X', 'X.X', '.X.'],
  'P': ['XX.', 'X.X', 'XX.', 'X..', 'X..'],
  'Q': ['.X.', 'X.X', 'X.X', 'XX.', '.XX'],
  'R': ['XX.', 'X.X', 'XX.', 'X.X', 'X.X'],
  'S': ['.XX', 'X..', '.X.', '..X', 'XX.'],
  'T': ['XXX', '.X.', '.X.', '.X.', '.X.'],
  'U': ['X.X', 'X.X', 'X.X', 'X.X', 'XXX'],
  'V': ['X.X', 'X.X', 'X.X', 'X.X', '.X.'],
  'W': ['X...X', 'X...X', 'X.X.X', 'XX.XX', 'X...X'],
  'X': ['X.X', 'X.X', '.X.', 'X.X', 'X.X'],
  'Y': ['X.X', 'X.X', '.X.', '.X.', '.X.'],
  'Z': ['XXX', '..X', '.X.', 'X..', 'XXX'],
  ' ': ['...', '...', '...', '...', '...'],
  ':': ['...', '.X.', '...', '.X.', '...'],
  '!': ['.X.', '.X.', '.X.', '...', '.X.'],
  '-': ['...', '...', 'XXX', '...', '...'],
  '/': ['..X', '..X', '.X.', 'X..', 'X..'],
  '<': ['..X', '.X.', 'X..', '.X.', '..X'],
  '>': ['X..', '.X.', '..X', '.X.', 'X..'],
};

int glyphAdvance(String ch) => (glyphs[ch]?[0].length ?? 3) + glyphSpacing;

int textWidth(String text, {int scale = 1}) {
  if (text.isEmpty) return 0;
  var width = 0;
  for (final ch in text.toUpperCase().split('')) {
    width += glyphAdvance(ch);
  }
  return (width - glyphSpacing) * scale;
}
