import { ModelData } from "./ConvertToTableData";

export function addIconDataToArray(array: ModelData[]): ModelData[] {
	array.map((item: any) => {
		item.attributes["icon"] = item.attributes.connector.icon;
	});
	return array;
}
