export type TableDataType = {
    columns : Array<string>;
    data: []
};

export type TableType = {
	title?: string;
	data: TableDataType;
};
