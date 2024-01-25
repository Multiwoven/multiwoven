export type TableDataType = {
	columns: Array<string>;
	data: Array<{}>;
};

export type ModelTableDataType = {
	columns: Array<string>;
	data: Array<{
		name: string | JSX.Element;
		method: string | JSX.Element;
		last_updated: string | JSX.Element;
	}>;
};

export type TableType = {
	title?: string | JSX.Element;
	data: TableDataType | ModelTableDataType;
	size?: string;
	headerColor?: string;
	headerColorVisible?: boolean;
	borderRadius?:string;
};
