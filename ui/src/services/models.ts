import {
  CreateModelPayload,
  CreateModelResponse,
  GetModelByIdResponse,
} from '@/views/Models/types';
import { apiRequest, multiwovenFetch } from './common';
import { UpdateModelPayload } from '@/views/Models/ViewModel/types';
import { ApiResponse } from './common';

export type APIData = {
  data?: Array<GetAllModelsResponse>;
  links?: Record<string, string>;
};

export type ModelAPIResponse<T> = {
  success: boolean;
  data?: T;
};

type ModelPreviewPayload = {
  query: string;
};

export type Field = {
  [key: string]: string | number | null;
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

export type ModelQueryType = 'data' | 'ai_ml' | 'raw_sql' | 'dbt' | 'soql' | 'table_selector';

export type GetAllModelsProps = {
  type: ModelQueryType;
  page?: number;
};

export const getModelPreview = async (query: string, connector_id: string): Promise<any> => {
  const url = '/connectors/' + connector_id + '/query_source';
  return apiRequest(url, { query: query });
};

export const getAllModels = async ({
  type = 'data',
  page = 1,
}: GetAllModelsProps): Promise<ApiResponse<GetAllModelsResponse[]>> =>
  multiwovenFetch<null, ApiResponse<GetAllModelsResponse[]>>({
    method: 'get',
    url: `/models?page=${page}&per_page=10&query_type=${type}`,
  });

export const getModelPreviewById = async (query: string, id: string) =>
  multiwovenFetch<ModelPreviewPayload, ApiResponse<Field[]>>({
    method: 'post',
    url: '/connectors/' + id + '/query_source',
    data: { query: query },
  });

export const createNewModel = async (payload: CreateModelPayload) =>
  multiwovenFetch<CreateModelPayload, ApiResponse<CreateModelResponse>>({
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
): Promise<ApiResponse<GetModelByIdResponse>> =>
  multiwovenFetch<UpdateModelPayload, ApiResponse<GetModelByIdResponse>>({
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
