// multiwovenFetch({
//     path: "",
//     method: "",
//     data: {},
//   }).then(());

import { axiosInstance } from "./axios";

type MultiwovenFetch = {
  path: string;
  method: "GET" | "POST";
  data?: Record<string, string>;
}

type APISuccessResponse = {

}

const multiwovenFetch = <ApiResponse>({ path, method, data }:MultiwovenFetch) : Promise<ApiResponse > => {

    return new Promise(()=>{})
};



// login screen


type LoginApiResponse = {
    token: string;
    error?:'Something went wrong'
}

type LoginErrorResponse = {
    error : string;
}


async function apiCall (){

const response = await multiwovenFetch<LoginApiResponse >({
    path: '/connectors',
    method: 'GET'
});

if(response?.error){
    //do something
}

const {token} = response

} 


export default multiwovenFetch;

