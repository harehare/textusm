type CanvasItem = {
  title: string;
  text: string[];
};

function toString(item: CanvasItem) {
  return `${item.title}
${(item.text ? item.text : [])
  .map((line) => {
    return `    ${line}`;
  })
  .join("\n")}
`;
}

export { CanvasItem, toString };
