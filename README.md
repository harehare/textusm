# TextUSM

[![Build Status](https://travis-ci.com/harehare/textusm.svg?branch=master)](https://travis-ci.com/harehare/textusm) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

TextUSM is a simple tool. Help you draw user story map using indented text.

![image](./img/textusm.gif)

## Features

- Generate a Diagram from indented text
  - User Story Map
  - Business Model Canvas
  - Opportunity Canvas
  - User Persona
  - Cost-benfit Analysis
  - 4Ls Retrospective
  - Start, Stop, Continue Retrospective
  - KPT Retrospective
  - Mind Map
- Export a Diagram
  - SVG
  - PNG
  - TXT
  - Trello
  - Github

## Example

### User Story Map

```
# labels: USER ACTIVITIES, USER TASKS, USER STORIES, RELEASE1, RELEASE2, RELEASE3
# release1: 2019-06-01
# release2: 2019-06-30
# release2: 2019-07-31
TextUSM
    Online tool for making user story mapping
        Press Tab to indent lines
        Press Shift + Tab to unindent lines: Online tool for Generate a User Story Mapping from indented text.
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
    Liked
Learned
    Learned
Lacked
    Lacked
Longed for
    Longed for
```

![image](./img/4ls.png)

### Start, Stop, Continue Retrospective

```
Start
    Start
Stop
    Stop
Continue
    Continue
```

![image](./img/ssc.png)

### KPT Retrospective

```
Keep
    Keep
Problem
    Problem
Try
    Try
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

## Installation

- [Web](https://textusm.com)
- [VSCode Extension](https://marketplace.visualstudio.com/items?itemName=harehare.textusm)
- [cli](https://www.npmjs.com/package/textusm.cli)
- [npm](https://www.npmjs.com/package/textusm)

## Developing

```sh
$ npm run dev
```

Open http://localhost:3000 and start modifying the code in /src.

## Production

```sh
npm run prod
```

## Testing

```
$ npm run test
```

<hr />

## License

[MIT](http://opensource.org/licenses/MIT)
