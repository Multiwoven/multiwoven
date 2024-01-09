// services/login.ts
import { axiosInstance as axios } from "./axios";

export const login = async (values: any) => {
	let data = JSON.stringify(values);
	try {
		const response = await axios.post("/login", data);
		return { success: true, response };
	} catch (error: any) {
		return { success: false };
	}
};

// function errorToLine(errors:Array<String[]>) {
//     return errors.map(row => row.join(' '));
// }

export const signUp = async (values: any) => {
	let data = JSON.stringify(values);
	try {
		const response = await axios.post("/signup", data);
		return { success: true, response };
	} catch (error: any) {
		return { success: false };
	}
};

export const accountVerify = async (values: any) => {
	let data = JSON.stringify(values);
	try {
		const response = await axios.post("/account-verify", data);
		return { success: true, response };
	} catch (error: any) {
		return { success: false };
	}
};

export async function getUserConnectors() {
	try {
		const response = await axios.get("/connectors");
		return { success: true, data: response.data };
	} catch (error) {
		// console.log(error);  
		return { success: false, error: error };
	}
}

export async function getUserConnector(connectorID:string) {
	try {
		const response = await axios.get("/connectors/" + connectorID);
		return { success: true, data: response.data };
	} catch (error) {
		console.log(error);
		return { success: false, error: error };
	}
}

export async function getConnectorsDefintions(connectorType: string) {
	try {
		const response = await axios.get(
			"/connector_definitions?type=" + connectorType
		);
		return { success: true, data: response.data };
	} catch (error) {
		return { success: false, error: error };
	}
}

export async function getConnectorDefinition(
	connectorType: string,
	connectorName: string
) {
	try {
		const response = await axios.get(
			"/connector_definitions/" + connectorName + "?type=" + connectorType
		);
		return { success: true, data: response.data };
	} catch (error) {
		return { success: false, error: error };
	}
}
