type Kanban = {
  name: "Kanban";
  lists: KanbanList[];
};

type KanbanList = {
  name: string;
  cards: KanbanCard[];
};

type KanbanCard = {
  text: string;
};

function toString(kanban: Kanban): string {
  return kanban.lists
    .map((list) => {
      return (
        `${list.name}\n` +
        list.cards.map((card) => `    ${card.text}`).join("\n")
      );
    })
    .join("\n");
}

export { Kanban, KanbanList, KanbanCard, toString };
