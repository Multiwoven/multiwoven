import { lazy } from 'react';
import SuspenseWithLoader from './main';

const AddMember = lazy(() => import('@/views/Sidebar/Workspace/AddMember'));

export type WorkspaceRouteItem = {
  name: string;
  url: string;
  component: JSX.Element;
};

export const WORKSPACE_ROUTES: WorkspaceRouteItem[] = [
  {
    name: 'Add Member',
    url: '/workspaces/:workspaceId/add-member',
    component: (
      <SuspenseWithLoader redirectRoute='/'>
        {/* We're removing this route approach since we now use inline modals */}
        {/* This route will be unused but kept for backward compatibility */}
        {/* The workspaceId is now handled directly in ManageWorkspaceModal */}
        <AddMember 
          onCancel={() => window.history.back()} 
          workspaceId="route-deprecated" 
          onSuccess={() => { /* Optional callback, not used in route version */ }}
        />
      </SuspenseWithLoader>
    ),
  },
];
