// services/login.ts
import { axiosInstance as axios} from './axios';

export const login  = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/login', data);
        return { success: true, response };
    } catch (error:any) {
        return { success: false, error: error.response.data.error };
    }
};

