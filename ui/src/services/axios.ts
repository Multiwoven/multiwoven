import axios from 'axios';
import Cookies from 'js-cookie';
import { useConfigStore } from '@/stores/useConfigStore';

export interface ApiResponse {
  success: boolean;
  data?: any;
  links?: Record<string, string>;
}

// Function to create axios instance with the current apiHost
function createAxiosInstance(apiHost: string) {
  const instance = axios.create({
    baseURL: `${apiHost}/api/v1/`,
  });

  instance.interceptors.request.use(function requestSuccess(config) {
    const token = Cookies.get('authToken');
    config.headers['Content-Type'] = 'application/json';
    config.headers['Authorization'] = `Bearer ${token}`;
    config.headers['Accept'] = '*/*';
    return config;
  });

  instance.interceptors.response.use(
    function responseSuccess(config) {
      return config;
    },
    function responseError(error) {
      if (error && error.response && error.response.status) {
        switch (error.response.status) {
          case 401:
            if (window.location.pathname !== '/sign-in') {
              window.location.href = '/sign-in';
              Cookies.remove('authToken');
            }
            break;
          case 403:
            break;
          case 501:
            break;
          case 500:
            break;
          default:
            break;
        }
      }
      return Promise.reject(error);
    },
  );

  return instance;
}

let axiosInstance = createAxiosInstance(useConfigStore.getState().configs.apiHost);

// Subscribe to changes in the Zustand store and recreate axios instance when apiHost changes
useConfigStore.subscribe((state) => {
  axiosInstance = createAxiosInstance(state.configs.apiHost);
});

export const apiRequest = async (url: string, values: any): Promise<ApiResponse> => {
  const data = JSON.stringify(values);
  let response;
  try {
    if (values === null) {
      response = await axiosInstance.get(url);
    } else {
      response = await axiosInstance.post(url, data);
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
    return axiosInstance
      .post(url, data)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  if (method === 'put')
    return axiosInstance
      .put(url, data)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  if (method === 'delete')
    return axiosInstance
      .delete(url)
      .then((res) => res?.data)
      .catch((err) => err?.response);

  return axiosInstance
    .get(url)
    .then((res) => res?.data)
    .catch((err) => err?.response);
};
