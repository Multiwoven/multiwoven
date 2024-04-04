export type ModelTableDataType = {
  columns: Array<string>;
  data: Array<{
    name: string | JSX.Element;
    method: string | JSX.Element;
    last_updated: string | JSX.Element;
  }>;
};

export type ColumnMapType = {
  name: string;
  key: string;
  showIcon?: boolean;
};
