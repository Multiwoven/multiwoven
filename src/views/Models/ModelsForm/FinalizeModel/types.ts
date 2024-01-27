import { ColumnMapType } from "@/utils/types";

export type SQLModel = {
	columns: Array<ColumnMapType>;
	id: string | number;
	query: string;
	query_type: string;
};
