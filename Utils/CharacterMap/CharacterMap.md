# CharacterMap Utility

A ComputerCraft utility program that displays all available characters (0-255) in a formatted grid layout, created by Xylopia.

## Features

- Displays all 256 ASCII characters in a 16x16 grid
- Shows character codes in both decimal and hexadecimal formats
- Interactive toggle between decimal and hexadecimal display
- Clear visual layout with column and row headers
- Easy-to-use controls

## Interface

The interface consists of:
- Header showing program title and current display mode
- Control instructions
- 16x16 character grid with hex row/column headers
- Character code ranges displayed on the right side

## Controls

- **Space**: Toggle between decimal and hexadecimal character codes
- **Q**: Quit the program

## Display Format

```
Character Map - All Characters (0-255)
Showing Decimal/Hex Codes
Controls: Space=Toggle Hex/Dec | Q=Quit
----------------------------------------
   00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
0:     ☺  ☻  ♥  ♦  ♣  ♠  •  ◘        ♂  ♀     ♪  ♫
...
```

## Technical Details

- Grid Size: 16x16 (256 characters total)
- Character Range: 0-255
- Display Modes: Decimal (\000-\255) or Hexadecimal (\00-\FF)
- Terminal Requirements: Minimum 80x27 characters

## Installation

1. Save the file as `CharacterMap.lua` in your ComputerCraft computer
2. Run using `CharacterMap`

## Use Cases

- Character reference for ASCII art
- Debugging text displays
- Finding special characters for programs
- Learning about ASCII/extended character sets
