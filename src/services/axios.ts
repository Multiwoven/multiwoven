import axios from 'axios';
import Cookies from 'js-cookie';

export const domain = "https://api.multiwoven.com/api/v1";
export const axiosInstance = axios.create({
	baseURL: domain,
});

axiosInstance?.interceptors.request.use(function requestSuccess(config) {
    const token = Cookies.get('authToken');
    config.headers['Content-Type'] = 'application/json';
    config.headers['Authorization'] = `Bearer ${token}`;
    config.headers["Accept"] = "*/*";
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
                case 403:
                case 501:
                case 500:
                    break;
                // Add more cases if needed
                default:
                    break;
            }
        }
        

		return Promise.reject(error);
	}
);
