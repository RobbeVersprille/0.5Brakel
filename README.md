# 0.5Brakel

## Code Rules

- write everything in English

### instructions:
  - upper case:
    -   ~~sta #$5001~~; NO
    -   STA #$5001; YES
  - end every line with a comment

### naming convention:

| type         | case              |
|--------------|-------------------|
| constants    | scream case       |
| variables    | snake case        |
| subroutines  | upper camel case  |
| local labels | lower camel case  |

```asm
  CONSTANT_VALUE = $05   ; scream case
  x_pos: .res 1          ; snake case

  .proc Subroutine:      ; upper camel case
  localLabel:            ; lower camel case
  .endproc
```
