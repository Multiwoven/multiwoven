import { multiwovenFetch } from './common';

export type WorkspaceAPIResponse = {
  data: {
    id: number;
    type: string;
    attributes: {
      name: string;
      slug: string;
      description: string;
      status: string;
      created_at: string;
      updated_at: string;
      region: string;
      organization_name: string;
      organization_id: number;
      members_count: number;
    };
  }[];
};

type UpdateWorkspaceResponse = {
  data: {
    attributes: {
      name: string;
    };
  };
};

export type CreateWorkspaceResponse = {
  name: string;
  description: string;
  organization_id: number;
  region?: string;
};

export const getWorkspaces = async (): Promise<WorkspaceAPIResponse> =>
  multiwovenFetch<null, WorkspaceAPIResponse>({
    method: 'get',
    url: '/workspaces',
  });

export const updateWorkspace = (
  payload: CreateWorkspaceResponse,
  id: number,
): Promise<UpdateWorkspaceResponse> =>
  multiwovenFetch<CreateWorkspaceResponse, UpdateWorkspaceResponse>({
    method: 'put',
    url: `/workspaces/${id}`,
    data: payload,
  });

export const createWorkspace = (
  payload: CreateWorkspaceResponse,
): Promise<UpdateWorkspaceResponse> =>
  multiwovenFetch<CreateWorkspaceResponse, UpdateWorkspaceResponse>({
    method: 'post',
    url: `/workspaces`,
    data: payload,
  });
