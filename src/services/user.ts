import { multiwovenFetch } from "./common";

export type ProfileAPIResponse = {
	data?: {
        id: number;
        type: string;
        attributes : {
            name: string;
            email: string;
        }
    }
};

export const getUserProfile = async () : Promise<ProfileAPIResponse> =>
	multiwovenFetch<null, ProfileAPIResponse>({
		method: "get",
		url: "/users/me",
	});

export const logout = async () => 
    multiwovenFetch<null,null>({
        method: "post",
        url: "/logout",
    })