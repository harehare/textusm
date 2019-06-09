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

```sh
textusm -i input.txt -o output.html
```

```sh
textusm -i input.txt -o output.html -d businessmodelcanvas
```

## Options

```
Usage: textusm [options]

Options:
  -V, --version                    output the version number
  -c, --configFile [configFile]    Config file.
  -i, --input <input>              Input text file. Required.
  -w, --width <width>              Width of the page. Optional. Default: 1024.
  -H, --height <height>            Height of the page. Optional. Default: 1024.
  -o, --output [output]            Output file. It should be svg, png, pdf or html.
  -d, --diagramType [diagramType]  Diagram type. It should be userstorymap, opportunitycanvas or businessmodelcanvas.
  -h, --help                       output usage information
```

## Example Input file

### User Story Map

```
# Comment
TextUSM
    Online tool for making user story mapping
        Press Tab to indent lines
        Press Shift + Tab to unindent lines: Note
```

![image](./img/usm.png)

### Business Model Canvas

```
👥 Key Partners
    Key Partners
📊 Customer Segments
    Customer Segments
🎁 Value Proposition
    Value Proposition
✅ Key Activities
    Key Activities
🚚 Channels
    Channels
💰 Revenue Streams
    Revenue Streams
🏷️ Cost Structure
    Cost Structure
💪 Key Resources
    Key Resources
💙 Customer Relationships
    Customer Relationships
```

![image](./img/bmc.png)

### Opportunity Canvas

```
Problems
    Problems
Solution Ideas
    Solution Ideas
Users and Customers
    Users and Customers
Solutions Today
    Solutions Today
Business Challenges
    Business Challenges
How will Users use Solution?
    How will Users use Solution?
User Metrics
    User Metrics
Adoption Strategy
    Adoption Strategy
Business Benefits and Metrics
    Business Benefits and Metrics
Budget
    Budget
```

![image](./img/opc.png)

## Example JSON configuration file

```json
{
  "font": "Open Sans",
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
