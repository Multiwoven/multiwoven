import {
  Connector,
  ConnectorInfoResponse,
  ConnectorListResponse,
  CreateConnectorPayload,
  CreateConnectorResponse,
  TestConnectionPayload,
  TestConnectionResponse,
} from '@/views/Connectors/types';
import { apiRequest, multiwovenFetch } from './common';
import { RJSFSchema } from '@rjsf/utils';
import { buildUrlWithParams } from './utils';

export type ConnectorsDefinationApiResponse = {
  success: boolean;
  data?: Connector[];
};

type ConnectorDefinationApiResponse = {
  success: boolean;
  data?: {
    icon: string;
    name: string;
    connector_spec: {
      documentation_url: string;
      connection_specification: RJSFSchema;
      supports_normalization: boolean;
      supports_dbt: boolean;
      stream_type: string;
    };
  };
};

export const getConnectorsDefintions = async (
  connectorType: string,
<<<<<<< HEAD
): Promise<ConnectorsDefinationApiResponse> => {
  return apiRequest('/connector_definitions?type=' + connectorType, null);
};
=======
  connectorCategory = 'data',
): Promise<Connector[]> =>
  multiwovenFetch<null, Connector[]>({
    method: 'get',
    url: buildUrlWithParams('/connector_definitions', {
      type: connectorType,
      category: connectorCategory,
    }),
  });
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))

export const getConnectorDefinition = async (
  connectorType: string,
  connectorName: string,
): Promise<ConnectorDefinationApiResponse> => {
  return apiRequest(
    buildUrlWithParams(`/connector_definitions/${connectorName}`, { type: connectorType }),
    null,
  );
};

export const getConnectionStatus = async (payload: TestConnectionPayload) =>
  multiwovenFetch<TestConnectionPayload, TestConnectionResponse>({
    method: 'post',
    url: '/connector_definitions/check_connection',
    data: payload,
  });

export const createNewConnector = async (
  payload: CreateConnectorPayload,
): Promise<CreateConnectorResponse> =>
  multiwovenFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'post',
    url: '/connectors',
    data: payload,
  });

export const getConnectorInfo = async (id: string): Promise<ConnectorInfoResponse> =>
  multiwovenFetch<null, ConnectorInfoResponse>({
    method: 'get',
    url: `/connectors/${id}`,
  });

export const updateConnector = async (
  payload: CreateConnectorPayload,
  id: string,
): Promise<CreateConnectorResponse> =>
  multiwovenFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'put',
    url: `/connectors/${id}`,
    data: payload,
  });

export const getUserConnectors = async (connectorType: string): Promise<ConnectorListResponse> => {
  return multiwovenFetch<null, ConnectorListResponse>({
    method: 'get',
<<<<<<< HEAD
    url: `/connectors?type=${connectorType}`,
=======
    url: buildUrlWithParams('/connectors', {
      type: connectorType,
      category: connectorCategory,
      page: page,
      per_page: '10',
    }),
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))
    data: null,
  });
};

export const deleteConnector = async (id: string): Promise<ConnectorInfoResponse> =>
  multiwovenFetch<null, ConnectorInfoResponse>({
    method: 'delete',
    url: `/connectors/${id}`,
  });

export const getAllConnectors = async (): Promise<ConnectorListResponse> =>
  multiwovenFetch<null, ConnectorListResponse>({
    method: 'get',
    url: '/connectors',
  });
