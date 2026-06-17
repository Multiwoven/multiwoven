/**
 * Settings module mocks
 * Shared mock data and functions for Settings tests
 */

// ── Mock functions ──────────────────────────────────────────────────
export const mockNavigate = jest.fn();
export const mockShowToast = jest.fn();
export const mockRefetch = jest.fn();
export const mockGetWorkspaces = jest.fn();
export const mockUpdateWorkspace = jest.fn();

// ── Role mocks ──────────────────────────────────────────────────────

/** Admin: all permissions enabled, including alerts & hosted_datastore */
export const adminRoleMock = {
  attributes: {
    policies: {
      permissions: {
        workspace: { read: true, create: true, delete: true, update: true },
        user: { read: true, create: true, delete: true, update: true },
        audit_logs: { read: true, create: true, delete: true, update: true },
        alerts: { read: true, create: true, delete: true, update: true },
        hosted_datastore: { read: true, create: true, delete: true, update: true },
        connector: { read: true, create: true, delete: true, update: true },
        model: { read: true, create: true, delete: true, update: true },
        report: { read: true, create: true, delete: true, update: true },
        sync: { read: true, create: true, delete: true, update: true },
        sync_run: { read: true, create: true, delete: true, update: true },
        sync_record: { read: true, create: true, delete: true, update: true },
        data_app: { read: true, create: true, delete: true, update: true },
        connector_definition: { read: true, create: true, delete: true, update: true },
        billing: { read: true, create: true, delete: true, update: true },
        eula: { read: true, create: true, delete: true, update: true },
        sso: { read: true, create: true, delete: true, update: true },
        assistant: { read: true, create: true, delete: true, update: true },
        workflow: { read: true, create: true, delete: true, update: true },
        knowledge_base: { read: true, create: true, delete: true, update: true },
        tool: { read: true, create: true, delete: true, update: true },
      },
    },
  },
};

/** Member: user.create false → no Members tab; alerts & hosted_datastore enabled */
export const memberRoleMock = {
  attributes: {
    policies: {
      permissions: {
        workspace: { read: true, create: false, delete: false, update: false },
        user: { read: true, create: false, delete: false, update: false },
        audit_logs: { read: true, create: true, delete: true, update: true },
        alerts: { read: true, create: false, delete: false, update: false },
        hosted_datastore: { read: true, create: false, delete: false, update: false },
        connector: { read: true, create: true, delete: true, update: true },
        model: { read: true, create: true, delete: true, update: true },
        report: { read: true, create: true, delete: true, update: true },
        sync: { read: true, create: true, delete: true, update: true },
        sync_run: { read: true, create: true, delete: true, update: true },
        sync_record: { read: true, create: true, delete: true, update: true },
        data_app: { read: true, create: true, delete: true, update: true },
        connector_definition: { read: true, create: true, delete: true, update: true },
        billing: { read: true, create: false, delete: false, update: false },
        eula: { read: true, create: false, delete: false, update: false },
        sso: { read: false, create: false, delete: false, update: false },
        assistant: { read: true, create: true, delete: true, update: true },
        workflow: { read: true, create: true, delete: true, update: true },
        knowledge_base: { read: true, create: true, delete: true, update: true },
        tool: { read: true, create: true, delete: true, update: true },
      },
    },
  },
};

/** Viewer: minimal permissions — no audit_logs, no alerts, no hosted_datastore */
export const viewerRoleMock = {
  attributes: {
    policies: {
      permissions: {
        workspace: { read: true, create: false, delete: false, update: false },
        user: { read: true, create: false, delete: false, update: false },
        audit_logs: { read: false, create: false, delete: false, update: false },
        alerts: { read: false, create: false, delete: false, update: false },
        hosted_datastore: { read: false, create: false, delete: false, update: false },
        connector: { read: true, create: false, delete: false, update: false },
        model: { read: true, create: false, delete: false, update: false },
        report: { read: true, create: false, delete: false, update: false },
        sync: { read: true, create: false, delete: false, update: false },
        sync_run: { read: true, create: false, delete: false, update: false },
        sync_record: { read: true, create: false, delete: false, update: false },
        data_app: { read: true, create: false, delete: false, update: false },
        connector_definition: { read: true, create: false, delete: false, update: false },
        billing: { read: false, create: false, delete: false, update: false },
        eula: { read: false, create: false, delete: false, update: false },
        sso: { read: false, create: false, delete: false, update: false },
        assistant: { read: false, create: false, delete: false, update: false },
        workflow: { read: false, create: false, delete: false, update: false },
        knowledge_base: { read: false, create: false, delete: false, update: false },
        tool: { read: false, create: false, delete: false, update: false },
      },
    },
  },
};

// ── Workspace data mocks ────────────────────────────────────────────

export const mockWorkspaceAttributes = {
  name: 'Test Workspace',
  slug: 'test-workspace',
  description: 'A test workspace',
  workspace_logo_url: null,
  organization_logo_url: null,
  status: 'active',
  created_at: '2024-01-01T00:00:00.000Z',
  updated_at: '2024-01-01T00:00:00.000Z',
  region: 'us-east-1',
  organization_name: 'Test Org',
  organization_id: 1,
  members_count: 5,
};

export const mockWorkspaceData = {
  data: [
    {
      id: 42,
      type: 'workspace',
      attributes: mockWorkspaceAttributes,
    },
  ],
};

export const mockUpdateWorkspaceResponse = {
  data: {
    attributes: {
      name: 'Updated Workspace',
    },
  },
};
