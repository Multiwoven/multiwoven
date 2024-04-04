import {
  CreateModelPayload,
  CreateModelResponse,
  GetModelByIdResponse,
} from '@/views/Models/types';
import { apiRequest, multiwovenFetch } from './common';
import { UpdateModelPayload } from '@/views/Models/ViewModel/types';

export type APIData = {
  data?: Array<GetAllModelsResponse>;
  links?: Record<string, string>;
};

type ModelAPIResponse<T> = {
  success: boolean;
  data?: T;
};

type ModelPreviewPayload = {
  query: string;
};

export type Field = {
  [key: string]: string | number | null;
};

export type ModelPreviewResponse =
  | Field[]
  | {
      data: {
        status: number;
        errors?: {
          detail: string;
          status: number;
          title: string;
        }[];
      };
    };

export type ModelAttributes = {
  updated_at: string;
  created_at: string;
  query: string;
  query_type: string;
  icon: string;
  id: string;
  name: string;
  description: string;
  primary_key: string;
  connector: {
    icon: string;
    [key: string]: string | null;
  };
};

export type GetAllModelsResponse = {
  id: string;
  type: string;
  attributes: ModelAttributes;
};

// export const getAllModels = async (): Promise<ModelAPIResponse<APIData>> => {
//   return apiRequest("/models", null);
// };

export const getModelPreview = async (query: string, connector_id: string): Promise<any> => {
  const url = '/connectors/' + connector_id + '/query_source';
  return apiRequest(url, { query: query });
};

export const getAllModels = async (): Promise<APIData> =>
  multiwovenFetch<null, APIData>({
    method: 'get',
    url: '/models',
  });

export const getModelPreviewById = async (
  query: string,
  id: string,
): Promise<ModelPreviewResponse> =>
  multiwovenFetch<ModelPreviewPayload, ModelPreviewResponse>({
    method: 'post',
    url: '/connectors/' + id + '/query_source',
    data: { query: query },
  });

export const createNewModel = async (payload: CreateModelPayload): Promise<CreateModelResponse> =>
  multiwovenFetch<CreateModelPayload, CreateModelResponse>({
    method: 'post',
    url: '/models',
    data: payload,
  });

export const getModelById = async (id: string): Promise<ModelAPIResponse<GetModelByIdResponse>> =>
  multiwovenFetch<string, ModelAPIResponse<GetModelByIdResponse>>({
    method: 'get',
    url: '/models/' + id,
  });

export const putModelById = async (
  id: string,
  payload: UpdateModelPayload,
): Promise<ModelAPIResponse<GetModelByIdResponse>> =>
  multiwovenFetch<UpdateModelPayload, ModelAPIResponse<GetModelByIdResponse>>({
    method: 'put',
    url: '/models/' + id,
    data: payload,
  });

export const deleteModelById = async (
  id: string,
): Promise<ModelAPIResponse<GetModelByIdResponse>> =>
  multiwovenFetch<string, ModelAPIResponse<GetModelByIdResponse>>({
    method: 'delete',
    url: '/models/' + id,
  });
