import {
  TestConnectionPayload,
  TestConnectionResponse,
} from "@/views/Connectors/types";
import { apiRequest, multiwovenFetch } from "./common";

type ConnectorsDefinationApiResponse = {
  success: boolean;
  data?: {
    icon: string;
    name: string;
    connector_spec: Record<string, unknown>;
  };
};

export const getConnectorsDefintions = async (
  connectorType: string
): Promise<ConnectorsDefinationApiResponse> => {
  return apiRequest("/connector_definitions?type=" + connectorType, null);
};

export const getConnectorDefinition = async (
  connectorType: string,
  connectorName: string
): Promise<ConnectorsDefinationApiResponse> => {
  return apiRequest(
    "/connector_definitions/" + connectorName + "?type=" + connectorType,
    null
  );
};

export const getConnectionStatus = async (payload: TestConnectionPayload) =>
  multiwovenFetch<TestConnectionPayload, TestConnectionResponse>({
    method: "post",
    url: "/connector_definitions/check_connection",
    data: payload,
  });
