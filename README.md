# TextUSM

[![Build Status](https://travis-ci.com/harehare/textusm.svg?branch=master)](https://travis-ci.com/harehare/textusm) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Online tool for Generate a User Story Mapping from indented text.

![image](./img/textusm.gif)

## Features

- Generate a User Story Mapping from indented text
- Add List and card to Trello
- Replace the code block with the generated USM.
- Open TextUS

## Example

```
# Comment
TextUSM
    Online tool for making user story mapping
        Press Tab to indent lines
        Press Shift + Tab to unindent lines: Note
```

![image](./img/usm.png)

## Download

- [Web](https://textusm.web.app)
- [Android](https://play.google.com/store/apps/details?id=me.textusm.usm)
- [VSCode Extension](https://marketplace.visualstudio.com/items?itemName=harehare.textusm)
- [Chrome Extension](https://chrome.google.com/webstore/detail/godhdokkibfjekpoikkghnjgemibmhka)
- [CLI](https://www.npmjs.com/package/textusm.cli)

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
