import { multiwovenFetch } from './common';

export interface WorkspaceResponse {
  id: string;
  attributes: {
    name: string;
    slug: string;
    members_count: number;
    // Add other attributes as needed
  };
}

export interface WorkspaceMemberResponse {
  success: boolean;
  message?: string;
  data?: any;
}

export interface AddMemberPayload {
  email: string;
}

/**
 * Add a member to a workspace using the application's authentication system
 */
export const addMemberToWorkspace = async (workspaceId: string, email: string): Promise<WorkspaceMemberResponse> => {
  try {
    console.log('Making API request to add member:', { workspaceId, email });
    
    // Use multiwovenFetch which automatically handles authentication and headers
    const response = await multiwovenFetch<AddMemberPayload, any>({
      method: 'post',
      url: `/workspaces/${workspaceId}/members`,
      data: { email }
    });
    
    console.log('Response from API:', response);
    
    // Check if the response was successful
    if (response?.data) {
      return {
        success: true,
        message: 'Member added successfully',
        data: response.data
      };
    } else if (response?.errors) {
      // Handle API error responses
      const errorMessage = response.errors.map((err: any) => err.detail || err.title).join(', ');
      return {
        success: false,
        message: errorMessage || 'Failed to add member'
      };
    } else if (response?.error) {
      // Handle specific error message from API (like 'User not found')
      return {
        success: false,
        message: response.error
      };
    } else {
      return {
        success: false,
        message: 'No response from server'
      };
    }
  } catch (error: any) {
    console.error('Error in addMemberToWorkspace:', error);
    return {
      success: false,
      message: error.message || 'Failed to connect to server'
    };
  }
};

/**
 * Get workspace members using the application's authentication system
 * @param workspaceId The ID of the workspace
 * @returns Promise with response data
 */
export const getWorkspaceMembers = async (workspaceId: string) => {
  try {
    // Use multiwovenFetch which automatically handles authentication and headers
    const response = await multiwovenFetch<null, any>({
      method: 'get',
      url: `/workspaces/${workspaceId}/members`,
    });
    
    return response?.data || [];
  } catch (error) {
    console.error('Error in getWorkspaceMembers:', error);
    throw error;
  }
};
