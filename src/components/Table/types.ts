export type TableDataType = {
	columns: Array<string>;
	data: [{}];
};

export type ModelTableDataType = {
	columns: Array<string>;
	data: Array<{
		name: string;
		method: string;
		last_updated: string;
	}>;
};

export type TableType = {
	title?: string | JSX.Element;
	data: TableDataType | ModelTableDataType;
};
