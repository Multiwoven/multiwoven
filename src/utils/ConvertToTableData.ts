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
	apiData: Array<Object>
): TableDataType {
	console.log(apiData);

	console.log(Object.keys(apiData[0]));
	const column_names = Object.keys(apiData[0]);

	const columns = column_names.map((column_name) => {
		return {
			name: column_name,
			key: column_name,
		};
	});

	return {
		columns: columns,
		data: apiData,
	};
}
