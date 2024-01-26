import { TableDataType } from "@/components/Table/types";
import { ColumnMapType } from "./types";

type ModelData = {
	id: string;
	type: string;
	icon: string;
	name: string;
	attributes: {
		[key: string]: string | null;
	};
};

export function ConvertToTableData(
	apiData: ModelData[],
	columnMap: ColumnMapType[]
): TableDataType {
	let data = apiData.map((item) => {
		let rowData: { [key: string]: string | null } = {};
		rowData = item.attributes;

		if (item.id) rowData["id"] = item.id;

		return rowData;
	});

	return {
		columns: columnMap,
		data: data,
	};
}

export function ConvertModelPreviewToTableData(
	apiData: Array<Object>,
	columns: Array<string>,
	customColumnNames?: Array<string>
): TableDataType {
	console.log(apiData);

	return {
		columns: customColumnNames ? customColumnNames : columns,
		data: apiData,
	};
}
