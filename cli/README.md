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
  -d, --diagramType [diagramType]  Diagram type. It should be one of userstorymap, opportunitycanvas, businessmodelcanvas, 4ls, start_stop_continue, kpt,
                                   userpersona, mind_map, empathy_map, customer_journey_map, site_map, gantt_chart.
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

### 4Ls Retrospective

```
Liked
  liked
Learned
  learned
Lacked
  lacked
Longed For
  longedFor
```

![image](./img/4ls.png)

### Start, Stop, Continue Retrospective

```
Start
  Start
Stop
  stop
Continue
  continue
```

![image](./img/ssc.png)

### KPT Retrospective

```
Keep
  keep
Problem
  problem
Try
  try
```

![image](./img/kpt.png)

### MindMap

```
TextUSM
    WORK QUICKLY
        Draw diagrams without leaving the keyboard.
    SAVE TIME
        Instantly visualize your ideas.
    EXPORT TO IMAGES
        Images can be exported as png or svg.
    SHARING
        Share your diagrams online with your colleagues.
```

![image](./img/mmp.png)

### Empathy Map

```
https://app.textusm.com/images/logo.svg
SAYS
THINKS
DOES
FEELS
```

![image](./img/emm.png)

### Customer Journey Map

```
Header
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Discover
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Research
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Purchase
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Delivery
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
Post-Sales
    Task
    Questions
    Touchpoints
    Emotions
    Influences
    Weaknesses
```

![image](./img/cjm.png)

### Site Map

```
Home
    Download
        TextUSM
        Help you draw user story map using indented text.
        WORK QUICKLY
        SAVE TIME
    Privacy Policy
        Test
    Terms
        Test
    Contacts
        harehare1110@gmail.com
```

![image](./img/smp.png)

### Gantt Chart

```
2019-12-26,2020-01-31: title
    subtitle1
        2019-12-26, 2019-12-31: task1
        2019-12-31, 2020-01-04: task2
```

![image](./img/gct.png)

### Impact Map

```
TextUSM
    WORK QUICKLY
        Draw diagrams without leaving the keyboard.
    SAVE TIME
        Instantly visualize your ideas.
    EXPORT TO IMAGES
        Images can be exported as png or svg.
    SHARING
        Share your diagrams online with your colleagues.
```

![image](./img/imm.png)

## Installation

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
      "label": "#8C9FAE",
      "text": "#111111"
    }
  }
}
```
