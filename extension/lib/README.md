# TextUSM

![](https://img.shields.io/badge/Release-v0.0.1-blue.svg?style=flat-square) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Generate a User Story Mapping from indented text.

## Installation

```bash
$ npm i -S textusm
```

## How to use

### Text

```javascript
const textusm = require('textusm');
const elm = document.getElementById('id');

textusm.render(
  elm || 'id',
  `
# labels: USER ACTIVITIES, USER TASKS, USER STORIES, RELEASE1, RELEASE2, RELEASE3
# release1: 2019-06-01
# release2: 2019-06-30
# release2: 2019-07-31
TextUSM
    Online tool for making user story mapping
        Press Tab to indent lines
        Press Shift + Tab to unindent lines: Online tool for Generate a User Story Mapping from indented text.`,
  // user story map size
  {
    size: { width: 1024, height: 1024 },
    showZoomControl: true
  },
  // user story map configuration
  {}
);
```

### Object

```javascript
const textusm = require('textusm');
const elm = document.getElementById('id');

textusm.render(
  elm || 'id',
  {
    activities: [
      {
        name: 'TextUSM',
        tasks: [
          {
            name: 'Online tool for making user story mapping',
            stories: [
              {
                name: 'Press Tab to indent lines',
                release: 1
              },
              {
                name:
                  'Press Shift + Tab to unindent lines: Online tool for Generate a User Story Mapping from indented text.',
                release: 1
              }
            ]
          }
        ]
      }
    ]
  },
  // user story map size
  {
    size: { width: 1024, height: 1024 },
    showZoomControl: true
  },
  // user story map configuration
  {}
);
```

![image](./img/usm.png)

### Configuration

```javascript
{
    font: "Open Sans",
    size: {
      width: 140,
      height: 65
    },
    backgroundColor: "#F5F5F6",
    color: {
      activity: {
        color: "#FFFFFF",
        backgroundColor: "#266B9A"
      },
      task: {
        color: "#FFFFFF",
        backgroundColor: "#3E9BCD"
      },
      story: {
        color: "#000000",
        backgroundColor: "#FFFFFF"
      },
      comment: {
        color: "#000000",
        backgroundColor: "#F1B090"
      },
      line: "#434343",
      label: "#8C9FAE"
    }
  }
}
```

## License

[MIT](http://opensource.org/licenses/MIT)
