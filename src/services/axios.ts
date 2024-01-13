import axios from 'axios';
import Cookies from 'js-cookie';
import toastr from "toastr";

toastr.options.preventDuplicates = true;

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
                    toastr.error(`${error.response.data.error.message}`);
                    break;
                // Add more cases if needed
                default:
                    toastr.error("An error occurred.");
                    break;
            }
        }
        

		return Promise.reject(error);
	}
);
