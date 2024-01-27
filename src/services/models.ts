import { apiRequest } from "./common";

type ModelAPIResponse = {
	success: boolean;
	data?: {
		id: string;
		type: string;
		icon: string;
		name: string;
		attributes: Record<string, unknown>;
	}[];
    links?: Record<string, string>;
};

export const getAllModels = async (): Promise<ModelAPIResponse> => {
	return apiRequest("/models", null);
};
