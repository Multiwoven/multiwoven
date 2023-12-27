import axios from 'axios';

const axiosInstance = axios.create({
    baseURL: 'https://api.multiwoven.com/v1'
});

export default axiosInstance;
