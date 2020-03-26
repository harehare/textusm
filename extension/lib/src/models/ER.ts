export type ERDiagram = {
  name: "ER";
  relations: (ManyToMany | OneToMany | ManyToOne | OneToOne)[];
  tables: Table[];
};

type ManyToMany = {
  table1: string;
  table2: string;
  relation: "=";
};

type OneToMany = {
  table1: string;
  table2: string;
  relation: "<";
};

type ManyToOne = {
  table1: string;
  table2: string;
  relation: ">";
};

type OneToOne = {
  table1: string;
  table2: string;
  relation: "-";
};

type Table = {
  name: string;
  columns: Column[];
};

type Column = {
  name: string;
  type: ColumnType;
  attribute: ColumnAttribute;
};

type ColumnType =
  | TinyIntType
  | IntType
  | FloatType
  | DoubleType
  | DecimalType
  | CharType
  | TextType
  | BlobType
  | VarCharType
  | BooleanType
  | TimestampType
  | DateType
  | DateTimeType
  | EnumType;

type ColumnTypeBase = {
  columnLength?: number;
  values?: string[];
};

type TinyIntType = ColumnTypeBase & {
  name: "tinyint";
};

type IntType = ColumnTypeBase & {
  name: "int";
};

type FloatType = ColumnTypeBase & {
  name: "float";
};

type DoubleType = ColumnTypeBase & {
  name: "double";
};

type DecimalType = ColumnTypeBase & {
  name: "decimal";
};

type CharType = ColumnTypeBase & {
  name: "char";
};

type TextType = ColumnTypeBase & {
  name: "text";
};

type BlobType = ColumnTypeBase & {
  name: "blob";
};

type VarCharType = ColumnTypeBase & {
  name: "varchar";
};

type BooleanType = ColumnTypeBase & {
  name: "boolean";
};

type TimestampType = ColumnTypeBase & {
  name: "timestamp";
};

type DateType = ColumnTypeBase & {
  name: "date";
};

type DateTimeType = ColumnTypeBase & {
  name: "datetime";
};

type EnumType = ColumnTypeBase & {
  name: "enum";
};

type ColumnAttribute =
  | PrimaryKey
  | NotNull
  | Null
  | Unique
  | Increment
  | Default
  | Index
  | None;

type ColumnAttributeBase = {
  value?: string;
};

type PrimaryKey = ColumnAttributeBase & {
  name: "pk";
};

type NotNull = ColumnAttributeBase & {
  name: "not null";
};

type Null = ColumnAttributeBase & {
  name: "null";
};

type Unique = ColumnAttributeBase & {
  name: "unique";
};

type Increment = ColumnAttributeBase & {
  name: "increment";
};

type Default = ColumnAttributeBase & {
  name: "default";
};

type Index = ColumnAttributeBase & {
  name: "index";
};

type None = ColumnAttributeBase & {
  name: "none";
};
