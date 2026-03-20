import axios, { AxiosRequestConfig } from 'axios';

import { useStore } from '@/stores';
import { useConfigStore } from '@/enterprise/store/useConfigStore';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { deleteCookie, getCookie } from './cookie';

export default function createBaseAxiosInstance(apiHost: string) {
  let loginRedirecting = false;
  const instance = axios.create({
    baseURL: `${apiHost}`,
  });

  instance.interceptors.request.use(function requestSuccess(config) {
    if (loginRedirecting) {
      return Promise.reject(
        new axios.CanceledError(`Session expired, hence cancelling the request: ${config.url}`),
      );
    }
    const token = getCookie('authToken');
    config.headers['Authorization'] = `Bearer ${token}`;
    config.headers['Workspace-Id'] = useStore.getState().workspaceId;
    config.headers['Accept'] = '*/*';

    if (config?.data?.appToken) {
      config.headers['Data-App-Id'] = config?.data?.appId;
      config.headers['Data-App-Token'] = config?.data?.appToken;
    }

    if (useConfigStore.getState().configs.appContext === 'embed') {
      const embedToken = getCookie('embedAuthToken');
      config.headers['X-App-Context'] = 'embed';
      config.headers['Authorization'] = `Bearer ${embedToken}`;
    }

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
            if (
              !loginRedirecting &&
              window.location.pathname !== '/sign-in' &&
              window.location.pathname !== '/sso-sign-in' &&
              !window.location.pathname.startsWith('/render/data-app')
            ) {
              window.location.href = '/sign-in';
              loginRedirecting = true;
              deleteCookie('authToken');
              useStore.getState().clearState();
              useRoleDataStore.getState().clearRoleData();
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
      return error.response;
    },
  );

  return instance;
}

export type MultiwovenFetchProps<PayloadType> = {
  url: string;
  method: 'get' | 'post' | 'put' | 'delete' | 'patch';
  data?: PayloadType;
  options?: AxiosRequestConfig;
  contentType?: 'json' | 'form';
};
