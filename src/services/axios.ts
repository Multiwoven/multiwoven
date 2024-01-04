import axios from 'axios';
// import cookie from 'react-cookies'

export const domain = 'https://api.multiwoven.com/api/v1'
export const axiosInstance = axios.create({
    baseURL: domain,
});

axiosInstance?.interceptors.request.use(function requestSuccess(config) {

    // config.headers["x-token"] = cookie.load('x-token') ? cookie.load('x-token') : "";
    config.headers['Content-Type']= 'application/json'
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