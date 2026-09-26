/// A 5x7 bitmap font in the spirit of old monochrome phone screens.
/// 'X' is a lit pixel. Letters and digits are 5 px wide; a few punctuation
/// glyphs are narrower.
const int glyphHeight = 7;
const int glyphSpacing = 1;

const Map<String, List<String>> glyphs = {
  '0': ['.XXX.', 'X...X', 'X..XX', 'X.X.X', 'XX..X', 'X...X', '.XXX.'],
  '1': ['..X..', '.XX..', '..X..', '..X..', '..X..', '..X..', '.XXX.'],
  '2': ['.XXX.', 'X...X', '....X', '...X.', '..X..', '.X...', 'XXXXX'],
  '3': ['XXXXX', '...X.', '..X..', '...X.', '....X', 'X...X', '.XXX.'],
  '4': ['...X.', '..XX.', '.X.X.', 'X..X.', 'XXXXX', '...X.', '...X.'],
  '5': ['XXXXX', 'X....', 'XXXX.', '....X', '....X', 'X...X', '.XXX.'],
  '6': ['..XX.', '.X...', 'X....', 'XXXX.', 'X...X', 'X...X', '.XXX.'],
  '7': ['XXXXX', '....X', '...X.', '..X..', '.X...', '.X...', '.X...'],
  '8': ['.XXX.', 'X...X', 'X...X', '.XXX.', 'X...X', 'X...X', '.XXX.'],
  '9': ['.XXX.', 'X...X', 'X...X', '.XXXX', '....X', '...X.', '.XX..'],
  'A': ['.XXX.', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X'],
  'B': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X...X', 'X...X', 'XXXX.'],
  'C': ['.XXX.', 'X...X', 'X....', 'X....', 'X....', 'X...X', '.XXX.'],
  'D': ['XXX..', 'X..X.', 'X...X', 'X...X', 'X...X', 'X..X.', 'XXX..'],
  'E': ['XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'XXXXX'],
  'F': ['XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'X....'],
  'G': ['.XXX.', 'X...X', 'X....', 'X.XXX', 'X...X', 'X...X', '.XXXX'],
  'H': ['X...X', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X'],
  'I': ['.XXX.', '..X..', '..X..', '..X..', '..X..', '..X..', '.XXX.'],
  'J': ['..XXX', '...X.', '...X.', '...X.', '...X.', 'X..X.', '.XX..'],
  'K': ['X...X', 'X..X.', 'X.X..', 'XX...', 'X.X..', 'X..X.', 'X...X'],
  'L': ['X....', 'X....', 'X....', 'X....', 'X....', 'X....', 'XXXXX'],
  'M': ['X...X', 'XX.XX', 'X.X.X', 'X.X.X', 'X...X', 'X...X', 'X...X'],
  'N': ['X...X', 'X...X', 'XX..X', 'X.X.X', 'X..XX', 'X...X', 'X...X'],
  'O': ['.XXX.', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.'],
  'P': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X....', 'X....', 'X....'],
  'Q': ['.XXX.', 'X...X', 'X...X', 'X...X', 'X.X.X', 'X..X.', '.XX.X'],
  'R': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X.X..', 'X..X.', 'X...X'],
  'S': ['.XXXX', 'X....', 'X....', '.XXX.', '....X', '....X', 'XXXX.'],
  'T': ['XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', '..X..'],
  'U': ['X...X', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.'],
  'V': ['X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.X.X.', '..X..'],
  'W': ['X...X', 'X...X', 'X...X', 'X.X.X', 'X.X.X', 'X.X.X', '.X.X.'],
  'X': ['X...X', 'X...X', '.X.X.', '..X..', '.X.X.', 'X...X', 'X...X'],
  'Y': ['X...X', 'X...X', '.X.X.', '..X..', '..X..', '..X..', '..X..'],
  'Z': ['XXXXX', '....X', '...X.', '..X..', '.X...', 'X....', 'XXXXX'],
  ' ': ['...', '...', '...', '...', '...', '...', '...'],
  ':': ['.', 'X', '.', '.', '.', 'X', '.'],
  '!': ['X', 'X', 'X', 'X', 'X', '.', 'X'],
  '-': ['....', '....', '....', 'XXXX', '....', '....', '....'],
  '/': ['....X', '....X', '...X.', '..X..', '.X...', 'X....', 'X....'],
  '<': ['...X', '..X.', '.X..', 'X...', '.X..', '..X.', '...X'],
  '>': ['X...', '.X..', '..X.', '...X', '..X.', '.X..', 'X...'],
};

int glyphAdvance(String ch) => (glyphs[ch]?[0].length ?? 5) + glyphSpacing;

int textWidth(String text, {int scale = 1}) {
  if (text.isEmpty) return 0;
  var width = 0;
  for (final ch in text.toUpperCase().split('')) {
    width += glyphAdvance(ch);
  }
  return (width - glyphSpacing) * scale;
}
