import axios from "axios";
import Cookies from "js-cookie";

export const domain = "https://api.multiwoven.com/api/v1";
export const axiosInstance = axios.create({
	baseURL: domain,
});

axiosInstance?.interceptors.request.use(function requestSuccess(config) {
	const token = Cookies.get("authToken");
	if (!token) {
		window.location.href = "/login";
	}
	config.headers["Content-Type"] = "application/json";
	config.headers["Authorization"] = `Bearer ${token}`;
	config.headers["Accept"] = "*/*";
	return config;
});


axiosInstance?.interceptors.response.use(
	function responseSuccess(config) {
		return config;
	},
	function responseError(error) {
        console.log(error.response.status);
        
		if (error && error.response && error.response.status) {
            
			switch (error.response.status) {
				case 401:
                    window.location.href = "/login";
					Cookies.remove("authToken");
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
	}
);
