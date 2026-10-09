import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import Sidebar from '../Sidebar';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Mock useAgentQueries
const mockWorkflowComponents = {
  schemas: [
    {
      id: 'comp-1',
      data: {
        component: 'llm',
        label: 'LLM Component',
        category: 'ai',
        icon: 'https://example.com/llm.svg',
        description: 'A language model component',
      },
    },
    {
      id: 'comp-2',
      data: {
        component: 'prompt',
        label: 'Prompt Template',
        category: 'ai',
        icon: 'https://example.com/prompt.svg',
        description: 'A prompt template component',
      },
    },
    {
      id: 'comp-3',
      data: {
        component: 'data_source',
        label: 'Data Source',
        category: 'data',
        icon: 'https://example.com/data.svg',
        description: 'A data source component',
      },
    },
  ],
};

jest.mock('@/enterprise/hooks/queries/useAgentQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetWorkflowComponents: () => ({
      data: mockWorkflowComponents,
      isLoading: false,
    }),
  }),
}));

// Mock constants
jest.mock('../../../constants', () => ({
  COMPONENT_CATEGORIES: [
    { name: 'AI', value: 'ai' },
    { name: 'DATA', value: 'data' },
  ],
}));

// Mock IconEntity
jest.mock('@/components/IconEntity', () => ({
  __esModule: true,
  default: ({ onClick }: { icon: React.ComponentType; onClick?: () => void }) => (
    <button data-testid='icon-entity' onClick={onClick}>
      Icon
    </button>
  ),
}));

// Mock SearchBar
jest.mock('@/components/SearchBar/SearchBar', () => ({
  __esModule: true,
  default: ({
    setSearchTerm,
    placeholder,
    'data-testid': dataTestId,
  }: {
    setSearchTerm: (term: string) => void;
    placeholder: string;
    'data-testid'?: string;
  }) => (
    <input
      data-testid={dataTestId ?? 'search-bar'}
      placeholder={placeholder}
      onChange={(e) => setSearchTerm(e.target.value)}
    />
  ),
}));

// Mock EntityItem
jest.mock('@/components/EntityItem', () => ({
  __esModule: true,
  default: ({ name }: { icon: string; name: string }) => (
    <div data-testid='entity-item'>{name}</div>
  ),
}));

// Mock react-icons
jest.mock('react-icons/tb', () => ({
  TbLayoutSidebarRightExpand: () => <span data-testid='expand-icon'>Expand</span>,
  TbLayoutSidebarRightCollapse: () => <span data-testid='collapse-icon'>Collapse</span>,
}));

jest.mock('react-icons/fi');

describe('Sidebar', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  const mockHandleDragEnd = jest.fn();

  const renderComponent = () => {
    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <Sidebar handleDragEnd={mockHandleDragEnd} />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render the sidebar', () => {
      renderComponent();
      expect(screen.getByText('Components')).toBeInTheDocument();
    });

    it('should render the description text when expanded', () => {
      renderComponent();
      expect(screen.getByText('Select a component for your workflow')).toBeInTheDocument();
    });

    it('should render search bar when expanded', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-sidebar-search')).toBeInTheDocument();
    });

    it('should render component categories', () => {
      renderComponent();
      expect(screen.getByText('AI')).toBeInTheDocument();
      expect(screen.getByText('DATA')).toBeInTheDocument();
    });

    it('should render component items', () => {
      renderComponent();
      expect(screen.getByText('LLM Component')).toBeInTheDocument();
      expect(screen.getByText('Prompt Template')).toBeInTheDocument();
      expect(screen.getByText('Data Source')).toBeInTheDocument();
    });
  });

  describe('Collapse/Expand', () => {
    it('should toggle sidebar when collapse icon is clicked', () => {
      renderComponent();

      // Initially expanded, should show description
      expect(screen.getByText('Select a component for your workflow')).toBeInTheDocument();

      // Click to collapse
      const iconButton = screen.getByTestId('icon-entity');
      fireEvent.click(iconButton);

      // After collapse, description should be hidden
      expect(screen.queryByText('Select a component for your workflow')).not.toBeInTheDocument();
    });

    it('should hide search bar when collapsed', () => {
      renderComponent();

      // Click to collapse
      const iconButton = screen.getByTestId('icon-entity');
      fireEvent.click(iconButton);

      expect(screen.queryByTestId('workflow-sidebar-search')).not.toBeInTheDocument();
    });
  });

  describe('Search', () => {
    it('should filter components when searching', () => {
      renderComponent();

      const searchInput = screen.getByTestId('workflow-sidebar-search');
      fireEvent.change(searchInput, { target: { value: 'LLM' } });

      // LLM should be visible
      expect(screen.getByText('LLM Component')).toBeInTheDocument();
    });

    it('should show no results when search matches nothing', () => {
      renderComponent();

      const searchInput = screen.getByTestId('workflow-sidebar-search');
      fireEvent.change(searchInput, { target: { value: 'nonexistent' } });

      // No components should match
      expect(screen.queryByText('LLM Component')).not.toBeInTheDocument();
      expect(screen.queryByText('Prompt Template')).not.toBeInTheDocument();
      expect(screen.queryByText('Data Source')).not.toBeInTheDocument();
    });
  });

  describe('Drag and Drop', () => {
    it('should render draggable components', () => {
      renderComponent();

      // Components should be present
      const entityItems = screen.getAllByTestId('entity-item');
      expect(entityItems.length).toBeGreaterThan(0);
    });

    it('should call handleDragEnd when drag ends', () => {
      renderComponent();

      // Find a draggable component container
      const draggableElements = document.querySelectorAll('[draggable="true"]');
      expect(draggableElements.length).toBeGreaterThan(0);

      // Trigger dragend event
      fireEvent.dragEnd(draggableElements[0]);

      expect(mockHandleDragEnd).toHaveBeenCalled();
    });
  });
});
