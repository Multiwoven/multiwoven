import { axiosInstance as axios } from "./axios";

function errorToLine(errors:Array<String[]>) {
    return errors.map(row => row.join(' '));
}

const signUp = async (values: any) => {
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

export default signUp;
