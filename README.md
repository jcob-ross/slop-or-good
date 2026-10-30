# For quick brain cache dumps

```bash
# build produces the same binary three times - as 'good', 'slop' and 'note'
zig build -Doptimize=ReleaseFast --prefix "$HOME/.local"


# all these just append timestamp and the text to a hardcoded file
good some text here # ~/Documents/note-good.txt
slop some other text here # ~/Documents/note-slop.txt
note a note here # ~/Documents/note-s.txt
```


This is my kind of slop.  
All this because fish shell can't handle '&' in unquoted text.
