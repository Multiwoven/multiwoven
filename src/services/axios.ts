import axios from 'axios';
import Cookies from 'js-cookie';
// import cookie from 'react-cookies'

export const domain = 'https://api.multiwoven.com/api/v1'
export const axiosInstance = axios.create({
    baseURL: domain,
});

axiosInstance?.interceptors.request.use(function requestSuccess(config) {
    config.headers['Content-Type']= 'application/json';
    config.headers['Authorization'] = Cookies.get('authToken');
    return config;
});

axiosInstance?.interceptors.response.use(
    function responseSuccess(config) {
        return config;
    },
    function responseError(error) {
        if (error && error.response && error.response.status === 401) {
            // window.alert("Authentication error.");
        }
        if (error && error.response && error.response.status === 403) {

            // window.alert("Authentication error.");
        }
        if (error && error.response && error.response.status === 501) {

        }
        if (error && error.response && error.response.status === 500) {

        }

        return Promise.reject(error);
    }
);