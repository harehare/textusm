# TextUSM

![](https://img.shields.io/badge/Release-v0.1.0-blue.svg?style=flat-square) ![](https://img.shields.io/badge/vscode-^1.33.0-blue.svg?style=flat-square) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

TextISM is a simple tool. Help you draw user story map using indented text.

- User Story Map
- Business Model Canvas
- Opportunity Canvas
- User Persona
- 4Ls Retrospective
- Start, Stop, Continue Retrospective
- KPT Retrospective
- Mind Map
- Empathy Map
- Table
- Site Map
- Gantt Chart
- Impact Map
- ER Diagram
- Kanban
- Sequence Diagram

![image](./img/textusm.gif)

https://textusm.com

# Features

## Available Commands

- `TextUSM: New Diagram`
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

### Table

```
Column1
    Column2
    Column3
    Column4
    Column5
    Column6
    Column7
Row1
    Column1
    Column2
    Column3
    Column4
    Column5
    Column6
Row2
    Column1
    Column2
    Column3
    Column4
    Column5
    Column6
```

![image](./img/table.png)

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

### ER Diagram

```
relations
    DiagramDetail - Diagram
    # One To Many
    User < Comment
    Diagram < Comment
    User < Diagram
    User < DiagramUser
    Diagram < DiagramUser
tables
    Diagram
        diagram_id int pk
        name varchar(255) not null
        type enum(userstorymap,mindmap)
        is_bookmark boolean default false
    DiagramDetail
        diagram_id int pk
        is_bookmark boolean default false
        is_public boolean default false
    Comment
        comment_id int pk
        comment text not null
        diagram_id int not null
        user_id int not null
    User
        user_id int pk
        name varchar(255)
    DiagramUser
        diagram_id int pk
        user_id int pk
```

![image](./img/erd.png)

### Kanban

```
TODO
    task1
    task1
DOING
    task2
    task2
DONE
    task3
    task3
```

![image](./img/kanban.png)

### Sequence Diagram

```
participant
    object1
    object2
    object3
object1 -> object2
    Sync Message
object1 ->> object2
    Async Message
object2 --> object1
    Reply Message
o-> object1
    Found Message
object1 ->o
    Stop Message
loop
    loop message
        object1 -> object2
            Sync Message
        object1 ->> object2
            Async Message
Par
    par message1
        object2 -> object3
            Sync Message
    par message2
        object1 -> object2
            Sync Message
```

![image](./img/sed.png)

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
  "textusm.task.color": "#000000"
}
```
