import { multiwovenFetch } from "./common";

export type SignUpPayload = {
	email: string;
	name: string;
	company_name: string;
	password: string;
	password_confirmation: string;
};

export type AuthResponse = {
	type: string;
	id: string;
	attributes: {
		token: string;
	};
	errors?: Array<{
		source: {
			[key: string]: string;
		};
	}>;
};

export type ApiResponse<T> = {
	data?: T;
	status: number;
};

export const signUp = async (payload: SignUpPayload) =>
	multiwovenFetch<SignUpPayload, ApiResponse<AuthResponse>>({
		method: "post",
		url: "/signup",
		data: payload,
	});
