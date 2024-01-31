import { ModelData } from "./ConvertToTableData";

export function AddIconDataToArray(array: ModelData[]): ModelData[] {
	array.map((item: any) => {
		item.attributes["icon"] = item.attributes.connector.icon;
	});
	return array;
}
