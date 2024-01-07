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

function errorToLine(errors:Array<String[]>) {
    return errors.map(row => row.join(' '));
}

export const signUp = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/signup', data);
        return { success: true, response };
    } catch (error:any) {
        const error_message_obj = error.response.data.error.details;
        const error_message = errorToLine(Object.entries(error_message_obj));
        return { success: false, error: error_message };
    }
};

export const accountVerify = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/account-verify', data);
        return { success: true, response };
    } catch (error:any) {
        return { success: false, error: error.response.data.error };
    }
};

