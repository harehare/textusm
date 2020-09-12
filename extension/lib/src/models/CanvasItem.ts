type CanvasItem = {
  title: string;
  text: string[];
};

let CanvasItem = {
  toString: (item: CanvasItem) => {
    return `${item.title}
${(item.text ? item.text : [])
  .map((line) => {
    return `    ${line}`;
  })
  .join("\n")}
`;
  },
};

export { CanvasItem };
