import { axiosInstance as axios } from './axios';

export interface ApiResponse {
  success: boolean;
  data?: any;
  links?: Record<string, string>;
}

export const apiRequest = async (url: string, values: any): Promise<ApiResponse> => {
  const data = JSON.stringify(values);
  let response;
  try {
    if (values === null) {
      response = await axios.get(url);
    } else {
      response = await axios.post(url, data);
    }

    return { success: true, data: response?.data };
  } catch (error) {
    return { success: false };
  }
};

export const login = async (values: any): Promise<ApiResponse> => {
  return apiRequest('/login', values);
};

export const signUp = async (values: any): Promise<ApiResponse> => {
  return apiRequest('/signup', values);
};

export const accountVerify = async (values: any): Promise<ApiResponse> => {
  return apiRequest('/verify_code', values);
};

export const getAllModels = async (): Promise<ApiResponse> => {
  return apiRequest('/models', null);
};

export const getUserConnectors = async (connectorType: string): Promise<ApiResponse> => {
  return apiRequest('/connectors?type=' + connectorType, null);
};

export const getUserConnector = async (connectorID: string): Promise<ApiResponse> => {
  return apiRequest('/connectors' + connectorID, null);
};

export const getConnectorsDefintions = async (connectorType: string): Promise<ApiResponse> => {
  return apiRequest('/connector_definitions?type=' + connectorType, null);
};

export const getConnectorDefinition = async (
  connectorType: string,
  connectorName: string,
): Promise<ApiResponse> => {
  return apiRequest('/connector_definitions/' + connectorName + '?type=' + connectorType, null);
};

export const getConnectorData = async (connectorID: string): Promise<ApiResponse> => {
  return apiRequest('/connectors/' + connectorID, null);
};

type MultiwovenFetchProps<PayloadType> = {
  url: string;
  method: 'get' | 'post' | 'put' | 'delete';
  data?: PayloadType;
};

export const multiwovenFetch = async <PayloadType, ResponseType>({
  url,
  method,
  data,
}: MultiwovenFetchProps<PayloadType>): Promise<ResponseType> => {
  if (method === 'post')
    return axios
      .post(url, data)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  if (method === 'put')
    return axios
      .put(url, data)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  if (method === 'delete')
    return axios
      .delete(url)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  return axios
    .get(url)
    .then((res) => res?.data)
    .catch((err) => err?.response);
};
