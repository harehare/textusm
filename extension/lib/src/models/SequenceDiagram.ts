type SequenceDiagram = {
  name: "SequenceDiagram";
  participants: Participant[];
  items: SequenceItem[];
};

type SequenceItem =
  | Alt
  | Opt
  | Par
  | Loop
  | Break
  | Critical
  | Assert
  | Neg
  | Ignore
  | Consider
  | Messages;

type Participant = string;

type Message = {
  kind: Sync | Async | Reply | Found | Lost;
  to: Participant;
  from: Participant;
  text: string;
};

type Messages = {
  kind: "messages";
  messages: Message[];
};

type SubMessage = {
  text: string;
  items: SequenceItem[];
};

type Alt = {
  kind: "alt";
  ifMessage: SubMessage;
  elseMessage: SubMessage;
};

type Opt = {
  kind: "opt";
  text: String;
  items: SequenceItem[];
};

type Par = {
  kind: "par";
  messages: SubMessage[];
};

type Loop = {
  kind: "loop";
  text: String;
  items: SequenceItem[];
};

type Break = {
  kind: "break";
  text: String;
  items: SequenceItem[];
};

type Critical = {
  kind: "critical";
  text: String;
  items: SequenceItem[];
};

type Assert = {
  kind: "assert";
  text: String;
  items: SequenceItem[];
};

type Neg = {
  kind: "neg";
  text: String;
  items: SequenceItem[];
};

type Ignore = {
  kind: "ignore";
  text: String;
  items: SequenceItem[];
};

type Consider = {
  kind: "consider";
  text: String;
  items: SequenceItem[];
};

type Sync = "->";
type Async = "->>";
type Reply = "-->";
type Found = "o->";
type Lost = "->o";

let SequenceDiagram = {
  toString: (sequenceDiagram: SequenceDiagram) => {
    const participants = `participants\n${sequenceDiagram.participants
      .map((name) => `    ${name}`)
      .join("\n")}`;
    const messages = sequenceDiagram.items
      .map(sequenceItemToString(0))
      .join("\n");

    return `${participants}\n${messages}`;
  },
};

const messageToString = (indent: number) => (message: Message) => {
  return `${"    ".repeat(indent)}${message.from} ${message.kind} ${
    message.to
  }\n${"    ".repeat(indent + 1)}${message.text}`;
};

const sequenceItemToString = (indent: number) => (
  sequenceItem: SequenceItem
) => {
  const spaces = "    ".repeat(indent);
  const textSpaces = "    ".repeat(indent + 1);
  switch (sequenceItem.kind) {
    case "messages":
      return sequenceItem.messages.map(messageToString(indent)).join("\n");

    case "alt":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.ifMessage.text
      }\n${sequenceItem.ifMessage.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}\n${textSpaces}${
        sequenceItem.elseMessage.text
      }\n${sequenceItem.elseMessage.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "par":
      return `${spaces}${sequenceItem.kind}\n${sequenceItem.messages
        .map(
          (subMessage) =>
            `${textSpaces}${subMessage.text}\n${subMessage.items
              .map((sub) => sequenceItemToString(indent + 2)(sub))
              .join("\n")}`
        )
        .join("\n")}`;

    case "opt":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "loop":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "break":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "critical":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "assert":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "neg":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "ignore":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    case "consider":
      return `${spaces}${sequenceItem.kind}\n${textSpaces}${
        sequenceItem.text
      }\n${sequenceItem.items
        .map(sequenceItemToString(indent + 2))
        .join("\n")}`;

    default:
      const _exhaustiveCheck: never = sequenceItem;
      return _exhaustiveCheck;
  }
};

export { SequenceDiagram };
