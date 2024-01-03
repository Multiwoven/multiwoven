// services/login.ts
import { axiosInstance as axios} from './axios';
import Cookies from 'js-cookie';

const login = async (values: any) => {
    let data = JSON.stringify(values);

    try {
        const response = await axios.post('/login', data);
        const token = response?.data?.token;
        Cookies.set('authToken', token);
        return { success: true, token };
    } catch (error:any) {
        console.error('Login error:', error);
        return { success: false, error: error.response.data.error };
    }
};

export default login;
