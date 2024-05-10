import axios from 'axios';
import Cookies from 'js-cookie';

// const DOMAIN =
//   window?.VITE_API_HOST !== '__VITE_API_HOST__' && window?.VITE_API_HOST !== 'undefined'
//     ? `${window?.VITE_API_HOST}/api/v1/`
//     : import.meta.env.VITE_API_HOST
//       ? `${import.meta.env.VITE_API_HOST}/api/v1/`
//       : 'http://localhost:3000/api/v1/';

// export const domain = DOMAIN;
const windowURL = window.location.href;
const isStaging = windowURL.includes('staging');

export const domain = isStaging
  ? 'https://api-staging.squared.ai/api/v1/'
  : 'https://api.squared.ai/api/v1/';
export const axiosInstance = axios.create({
  baseURL: domain,
});

axiosInstance?.interceptors.request.use(function requestSuccess(config) {
  const token = Cookies.get('authToken');
  config.headers['Content-Type'] = 'application/json';
  config.headers['Authorization'] = `Bearer ${token}`;
  config.headers['Accept'] = '*/*';
  return config;
});

axiosInstance?.interceptors.response.use(
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
