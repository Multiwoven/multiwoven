import { axiosInstance as axios } from "./axios";

async function getUserConnectors() {
  try {
    const response = await axios.get('/connectors');
    return { success: true, data: response.data };
  } catch (error) {
    return { success: false, error: error };
  }
}

export default getUserConnectors;
