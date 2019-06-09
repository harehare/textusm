# TextUSM

![](https://img.shields.io/badge/Release-v0.0.9-blue.svg?style=flat-square) ![](https://img.shields.io/badge/vscode-^1.33.0-blue.svg?style=flat-square) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Live Preview a User Story Mapping from indented text.

![image](./extension/vscode/img/textusm.gif)

https://textusm.web.app

# Features

## Available Commands

- `TextUSM: Open Preview`
- `TextUSM: Export SVG`
- `TextUSM: Export PNG`

# Example

## User Story Map

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

## Business Model Canvas

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

## Opportunity Canvas

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

## Options

```json
{
  "textusm.fontName": "Hiragino Kaku Gothic ProN",
  "textusm.exportDir": "/Users/sato_takahiro/Downloads",
  "textusm.backgroundColor": "#FFFFFF",
  "textusm.activity.backgroundColor": "#FFFFFF",
  "textusm.activity.color": "#000000",
  "textusm.story.backgroundColor": "#000000",
  "textusm.story.color": "#FFFFFFF",
  "textusm.task.backgroundColor": "#000000",
  "textusm.task.color": "#000000",
  "textusm.diagramType": "UserStoryMap"
}
```

## License

[MIT](http://opensource.org/licenses/MIT)
