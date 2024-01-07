// services/login.ts
import { axiosInstance as axios} from './axios';

export const login  = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/login', data);
        return { success: true, response };
    } catch (error:any) {
        return { success: false };
    }
};

// function errorToLine(errors:Array<String[]>) {
//     return errors.map(row => row.join(' '));
// }

export const signUp = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/signup', data);
        return { success: true, response };
    } catch (error:any) {
        return { success: false };
    }
};

export const accountVerify = async (values: any) => {
    let data = JSON.stringify(values);
    try {
        const response = await axios.post('/account-verify', data);
        return { success: true, response };
    } catch (error:any) {
        return { success: false };
    }
};

