type Table = {
  name: "Table";
  header: string[];
  items: string[][];
};

let Table = {
  toString: (table: Table): string => {
    const rows = table.items
      .map((item) =>
        item.length > 0
          ? `${item[0]}\n${item
              .slice(1)
              .map((v) => `    ${v}`)
              .join("\n")}`
          : ""
      )
      .join("\n");

    return table.header.length > 0
      ? `${table.header[0]}\n${table.header
          .map((v) => `    ${v}`)
          .splice(1)
          .join("\n")}\n${rows}`
      : "";
  },
};

export { Table };
