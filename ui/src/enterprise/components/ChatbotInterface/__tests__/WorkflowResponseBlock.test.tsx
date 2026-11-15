import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { expect, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import WorkflowResponseBlock from '../WorkflowResponseBlock';
import { WorkflowResponseData } from '../types';

const renderWithChakra = (ui: React.ReactElement) => render(<ChakraProvider>{ui}</ChakraProvider>);

jest.mock('@/enterprise/views/Agents/AgentWorkflow/Configbar/utils', () => ({
  getCategoryBaseColor: (category: string) => {
    const colorMap: Record<string, string> = {
      llm: 'purple',
      vector: 'blue',
      io: 'green',
    };
    return colorMap[category] ?? 'gray';
  },
}));

jest.mock('@/assets/icons/FiUndo.svg', () => 'FiUndoSvg');

jest.mock('../MissingConnectionCard', () => ({
  __esModule: true,
  default: ({ connectorName, isConnected, didLoad, onConnectClick, onRetryPrompt }: any) => (
    <div data-testid={`missing-card-${connectorName}`}>
      <span data-testid={`card-connected-${connectorName}`}>{String(isConnected)}</span>
      <span data-testid={`card-did-load-${connectorName}`}>{String(didLoad)}</span>
      <button data-testid={`connect-btn-${connectorName}`} onClick={onConnectClick}>
        Connect New
      </button>
      <button data-testid={`retry-btn-${connectorName}`} onClick={onRetryPrompt}>
        Retry Prompt
      </button>
    </div>
  ),
}));

jest.mock('../ConnectSourceDrawer', () => ({
  __esModule: true,
  default: ({ isOpen, onSuccess, onClose }: any) =>
    isOpen ? (
      <div data-testid='connect-drawer'>
        <button data-testid='drawer-success' onClick={onSuccess}>
          success
        </button>
        <button data-testid='drawer-close' onClick={onClose}>
          close
        </button>
      </div>
    ) : null,
}));

jest.mock('@/components/StatusTag/StatusTag', () => {
  const StatusTagVariants = {
    success: 'success',
    pending: 'pending',
    failed: 'failed',
  };
  const StatusTagText: Record<string, string> = {
    added: 'Added',
    modified: 'Modified',
    deleted: 'Deleted',
  };
  const StatusTag = ({ variant, status }: { variant: string; status: string }) => (
    <span data-testid='status-tag' data-variant={variant}>
      {status}
    </span>
  );
  return { __esModule: true, default: StatusTag, StatusTagVariants, StatusTagText };
});

const makeComponent = (overrides: Record<string, unknown> = {}) => ({
  id: 'comp-1',
  type: 'llm',
  position: { x: 0, y: 0 },
  data: {
    label: 'OpenAI LLM',
    icon: 'icon-url.svg',
    category: 'llm',
    ...overrides,
  },
});

const makeWorkflowData = (
  added: ReturnType<typeof makeComponent>[] = [],
  modified: ReturnType<typeof makeComponent>[] = [],
  deleted: ReturnType<typeof makeComponent>[] = [],
  missingConnectors: { name: string; category: string }[] = [],
): WorkflowResponseData => ({
  status: 200,
  data: {
    id: 'wf-1',
    type: 'agents-workflows',
    attributes: {
      name: 'Test Workflow',
      description: 'A test workflow',
      status: 'draft',
      components: [],
      edges: [],
    },
  } as any,
  meta: { changes: { added, modified, deleted }, missing_connectors: missingConnectors } as any,
});

describe('WorkflowResponseBlock', () => {
  describe('loading state', () => {
    test('renders a loading skeleton when loading=true', () => {
      renderWithChakra(<WorkflowResponseBlock loading />);
      // Skeleton is rendered — no "Generated workflow" text visible
      expect(screen.queryByText('Generated workflow')).not.toBeInTheDocument();
    });

    test('does not render component details when loading', () => {
      renderWithChakra(<WorkflowResponseBlock loading />);
      expect(screen.queryByText('Components')).not.toBeInTheDocument();
    });
  });

  describe('collapsed state (default)', () => {
    test('renders "Generated workflow" header text', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByText('Generated workflow')).toBeInTheDocument();
    });

    test('renders generated-workflow data-testid for E2E selectors', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByTestId('generated-workflow')).toBeInTheDocument();
    });

    test('does not show components section when collapsed', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.queryByText('Components')).not.toBeInTheDocument();
    });

    test('renders an expand button with aria-label "Expand"', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByRole('button', { name: 'Expand' })).toBeInTheDocument();
    });
  });

  describe('expanded state', () => {
    test('shows "Components" heading after clicking expand', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('Components')).toBeInTheDocument();
    });

    test('collapse button aria-label changes to "Collapse" when expanded', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByRole('button', { name: 'Collapse' })).toBeInTheDocument();
    });

    test('collapses again when Collapse button is clicked', () => {
      const workflowData = makeWorkflowData([makeComponent()]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('Components')).toBeInTheDocument();
      fireEvent.click(screen.getByRole('button', { name: 'Collapse' }));
      expect(screen.queryByText('Components')).not.toBeInTheDocument();
    });
  });

  describe('component list rendering', () => {
    test('renders added component labels and "Added" status badge', () => {
      const workflowData = makeWorkflowData([makeComponent({ label: 'OpenAI LLM' })]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('OpenAI LLM')).toBeInTheDocument();
      expect(screen.getByText('Added')).toBeInTheDocument();
    });

    test('renders modified component with "Modified" status badge', () => {
      const workflowData = makeWorkflowData([], [makeComponent({ label: 'Modified Component' })]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('Modified Component')).toBeInTheDocument();
      expect(screen.getByText('Modified')).toBeInTheDocument();
    });

    test('renders deleted component with "Deleted" status badge', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [makeComponent({ label: 'Deleted Component' })],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('Deleted Component')).toBeInTheDocument();
      expect(screen.getByText('Deleted')).toBeInTheDocument();
    });

    test('renders all three status types in order: added, modified, deleted', () => {
      const workflowData = makeWorkflowData(
        [makeComponent({ label: 'Added Comp' })],
        [makeComponent({ label: 'Modified Comp' })],
        [makeComponent({ label: 'Deleted Comp' })],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));

      const statusTags = screen.getAllByTestId('status-tag');
      expect(statusTags[0]).toHaveTextContent('Added');
      expect(statusTags[1]).toHaveTextContent('Modified');
      expect(statusTags[2]).toHaveTextContent('Deleted');
    });

    test('renders multiple added components', () => {
      const workflowData = makeWorkflowData([
        makeComponent({ label: 'LLM Node' }),
        makeComponent({ label: 'Vector Store' }),
      ]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      expect(screen.getByText('LLM Node')).toBeInTheDocument();
      expect(screen.getByText('Vector Store')).toBeInTheDocument();
    });

    test('renders empty component list without errors when all arrays are empty', () => {
      const workflowData = makeWorkflowData();
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      // No components → no Expand button and no status tags visible
      expect(screen.queryByRole('button', { name: 'Expand' })).not.toBeInTheDocument();
      expect(screen.queryAllByTestId('status-tag')).toHaveLength(0);
    });
  });

  describe('status tag variants', () => {
    test('added status uses success variant', () => {
      const workflowData = makeWorkflowData([makeComponent({ label: 'New Comp' })]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      const tag = screen.getByTestId('status-tag');
      expect(tag).toHaveAttribute('data-variant', 'success');
    });

    test('modified status uses pending variant', () => {
      const workflowData = makeWorkflowData([], [makeComponent({ label: 'Changed Comp' })]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      const tag = screen.getByTestId('status-tag');
      expect(tag).toHaveAttribute('data-variant', 'pending');
    });

    test('deleted status uses failed variant', () => {
      const workflowData = makeWorkflowData([], [], [makeComponent({ label: 'Removed Comp' })]);
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      fireEvent.click(screen.getByRole('button', { name: 'Expand' }));
      const tag = screen.getByTestId('status-tag');
      expect(tag).toHaveAttribute('data-variant', 'failed');
    });
  });

  describe('missing connectors state', () => {
    test('renders a card for each missing connector', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByTestId('missing-card-Postgres')).toBeInTheDocument();
    });

    test('renders multiple cards when multiple connectors are missing', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [
          { name: 'Postgres', category: 'database' },
          { name: 'Snowflake', category: 'warehouse' },
        ],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByTestId('missing-card-Postgres')).toBeInTheDocument();
      expect(screen.getByTestId('missing-card-Snowflake')).toBeInTheDocument();
    });

    test('isConnected starts as false', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByTestId('card-connected-Postgres')).toHaveTextContent('false');
    });

    test('clicking Connect New opens ConnectSourceDrawer; success marks connector as connected', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);

      fireEvent.click(screen.getByTestId('connect-btn-Postgres'));
      expect(screen.getByTestId('connect-drawer')).toBeInTheDocument();

      fireEvent.click(screen.getByTestId('drawer-success'));
      expect(screen.queryByTestId('connect-drawer')).not.toBeInTheDocument();
      expect(screen.getByTestId('card-connected-Postgres')).toHaveTextContent('true');
    });

    test('clicking close on ConnectSourceDrawer dismisses it without marking connector as connected', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);

      fireEvent.click(screen.getByTestId('connect-btn-Postgres'));
      expect(screen.getByTestId('connect-drawer')).toBeInTheDocument();

      fireEvent.click(screen.getByTestId('drawer-close'));
      expect(screen.queryByTestId('connect-drawer')).not.toBeInTheDocument();
      expect(screen.getByTestId('card-connected-Postgres')).toHaveTextContent('false');
    });

    test('onRetryPrompt is forwarded to each MissingConnectionCard and fires when called', () => {
      const retryMock = jest.fn();
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(
        <WorkflowResponseBlock workflowData={workflowData} onRetryPrompt={retryMock} />,
      );

      fireEvent.click(screen.getByTestId('retry-btn-Postgres'));
      expect(retryMock).toHaveBeenCalledTimes(1);
    });

    test('passes didLoad=true to MissingConnectionCard when loaded from history', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} didLoad={true} />);
      expect(screen.getByTestId('card-did-load-Postgres')).toHaveTextContent('true');
    });

    test('does not pass didLoad=true to MissingConnectionCard by default', () => {
      const workflowData = makeWorkflowData(
        [],
        [],
        [],
        [{ name: 'Postgres', category: 'database' }],
      );
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByTestId('card-did-load-Postgres')).not.toHaveTextContent('true');
    });
  });

  describe('error states', () => {
    test('renders error alert when workflowData is not provided and not loading', () => {
      renderWithChakra(<WorkflowResponseBlock />);
      expect(screen.getByText('Unable to display workflow')).toBeInTheDocument();
      expect(screen.getByText('The workflow response could not be loaded.')).toBeInTheDocument();
    });

    test('renders error alert when workflowData.data is null', () => {
      const workflowData: WorkflowResponseData = {
        status: 200,
        data: null as any,
        meta: { changes: { added: [], modified: [], deleted: [] }, missing_connectors: [] } as any,
      };
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByText('Unable to display workflow')).toBeInTheDocument();
      expect(screen.getByText('The workflow response could not be loaded.')).toBeInTheDocument();
    });

    test('renders error alert when workflowData.data is undefined', () => {
      const workflowData = {
        status: 200,
        meta: { changes: { added: [], modified: [], deleted: [] }, missing_connectors: [] },
      } as any;
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByText('Unable to display workflow')).toBeInTheDocument();
    });
  });

  describe('meta fallback branches', () => {
    test('renders normally when workflowData has no meta property', () => {
      const workflowData = {
        status: 200,
        data: {
          id: 'wf-1',
          type: 'agents-workflows',
          attributes: {
            name: 'Test Workflow',
            description: 'A test workflow',
            status: 'draft',
            components: [],
            edges: [],
          },
        },
      } as any;
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      expect(screen.getByText('Generated workflow')).toBeInTheDocument();
    });

    test('renders normally when meta.changes is absent', () => {
      const workflowData = {
        status: 200,
        data: {
          id: 'wf-1',
          type: 'agents-workflows',
          attributes: {
            name: 'Test Workflow',
            description: 'A test workflow',
            status: 'draft',
            components: [],
            edges: [],
          },
        },
        meta: { missing_connectors: [] },
      } as any;
      renderWithChakra(<WorkflowResponseBlock workflowData={workflowData} />);
      // No changes → no Expand button and no status tags
      expect(screen.queryByRole('button', { name: 'Expand' })).not.toBeInTheDocument();
      expect(screen.queryAllByTestId('status-tag')).toHaveLength(0);
    });
  });
});
