import axiosInstance from './axios';
//import { axiosInstance as axios } from "./axios";

// const signUp = async (email: string, password: string, confirmPassword: string) => {
//     try {
//         const response = await axiosInstance.post('/signup', 
//             { 
//                 "email": email, 
//                 "password": password, 
//                 "password_confirmation": confirmPassword,
//             }
//         );
//         if (response.status === 201) {
//             return "Successfully Registered"
//         } else if (response.status === 409) {
//             return "User already exists"
//         }
//     } catch (error) {
//         console.error('signUp error:', error);
//         throw error;
//     }
// };

// export default signUp;