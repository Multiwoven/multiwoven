import { ColumnMapType } from "@/utils/types";

export type TableDataType = {
  columns: Array<ColumnMapType>;
  data: Array<{}>;
};

export type ModelTableRow = {
  name: string | JSX.Element;
  method: string | JSX.Element;
  last_updated: string | JSX.Element;
};

export type ModelTableDataType = {
  columns: Array<string>;
  data: Array<ModelTableRow>;
};

export type TableType = {
  title?: string | JSX.Element;
  data: TableDataType;
  size?: string;
  headerColor?: string;
  headerColorVisible?: boolean;
  borderRadius?: string;
  maxHeight?: string;
  onRowClick?: (args: ModelTableRow | unknown) => void;
};
