export type CreateModelPayload = {
	model: {
		connector_id: number;
		name: string;
		description: string;
		query: string;
		query_type: string;
		primary_key: string;
	};
};

export type CreateModelResponse = {
	data: {
		attributes: unknown;
		id: string;
		type: string;
	};
};
