# TextUSM CLI

[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Generate a User Story Mapping from indented text.

CLI for [TextUSM](./README.md).

## Installation

```sh
$ npm i -g textusm.cli
```

## Examples

```sh
textusm -i input.txt -o output.svg
```

```sh
textusm -i input.txt -o output.png
```

```sh
textusm -i input.txt -o output.pdf
```

## Options

```
Usage: textusm [options]

Options:
  -V, --version                  output the version number
  -c, --configFile [configFile]  Config file.
  -i, --input <input>            Input text file. Required.
  -o, --output [output]          Output file. It should be svg, png or pdf.
  -h, --help                     output usage information
```

## Example Input file

```
# Comment
TextUSM
    Online tool for making user story mapping
        Press Tab to indent lines
        Press Shift + Tab to unindent lines: Note
```

## Example JSON configuration file

```json
{
  "font": "Open Sans",
  "position": 0,
  "text": "",
  "title": "TestUSM",
  "storyMap": {
    "font": "Open Sans",
    "size": {
      "width": 140,
      "height": 65
    },
    "backgroundColor": "#F5F5F6",
    "color": {
      "activity": {
        "color": "#FFFFFF",
        "backgroundColor": "#266B9A"
      },
      "task": {
        "color": "#FFFFFF",
        "backgroundColor": "#3E9BCD"
      },
      "story": {
        "color": "#000000",
        "backgroundColor": "#FFFFFF"
      },
      "comment": {
        "color": "#000000",
        "backgroundColor": "#F1B090"
      },
      "line": "#434343",
      "label": "#8C9FAE"
    }
  }
}
```
