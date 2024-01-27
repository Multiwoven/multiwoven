import {
	CreateModelPayload,
	CreateModelResponse,
} from "@/views/Models/types";
import { apiRequest, multiwovenFetch } from "./common";

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

export const getModelPreview = async (
	query: string,
	connector_id: string
): Promise<any> => {
	const url = "/connectors/" + connector_id + "/query_source";
	return apiRequest(url, { query: query });
};

export const createNewModel = async (
	payload: CreateModelPayload
): Promise<CreateModelResponse> =>
	multiwovenFetch<CreateModelPayload, CreateModelResponse>({
		method: "post",
		url: "/models",
		data: payload,
	});
