import { apiRequest } from "./common";

type APIData = {
	data?: Array<{
		id: string;
		type: string;
		icon: string;
		name: string;
		attributes: {
			[key: string]: string | null;
		};
	}>;
	links?: Record<string, string>;
};

type ModelAPIResponse = {
	success: boolean;
	data?: APIData;
};

export const getAllModels = async (): Promise<ModelAPIResponse> => {
	return apiRequest("/models", null);
};

export const getModelPreview = async (): Promise<any> => {
	return apiRequest("/models/3/preview", null);
};
