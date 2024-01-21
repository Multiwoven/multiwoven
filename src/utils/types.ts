export type ModelTableDataType = {
	columns: Array<string>;
	data: Array<{
		name: string | JSX.Element;
		method: string | JSX.Element;
		last_updated: string | JSX.Element;
	}>;
};