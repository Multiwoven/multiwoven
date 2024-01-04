import { axiosInstance as axios } from "./axios";

const getUserConnectors = ( userToken:string ) => {
    axios.get('/connectors', 
    {
        headers: {
            'Authorization': 'Bearer ' + userToken
        }        
    })
    .then((response) => {
        return { success:true, data: response.data }
    })
    .catch((error) => {
        return { success:false, error:error }
    })
}