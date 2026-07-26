import { fireEvent, screen } from '@testing-library/react';
import { expect, describe, it, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import AssistantsList from '../AssistantsList';
import useDataAppQueries from '@/enterprise/hooks/queries/useDataAppQueries';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import useFilters from '@/hooks/useFilters';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { renderWithProviders } from '@/utils/testUtils';
import { RENDERING_OPTION_TYPE } from '@/enterprise/views/DataApps/DataAppsForm/types';
import { mockApiErrorToast } from '../../../../../../__mocks__/commonMocks';

jest.mock('@/enterprise/hooks/queries/useDataAppQueries');
jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: jest.fn(),
}));
jest.mock('@/hooks/useFilters');
jest.mock('@/enterprise/hooks/useProtectedNavigate');
jest.mock('../NoAssistants', () => ({
  __esModule: true,
  default: () => <div data-testid='no-assistants'>No Assistants</div>,
}));
jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({ data, onRowClick, getRowProps }: any) => (
    <div data-testid='data-table'>
      {data.map((item: any) => {
        const row = { original: item, id: String(item.id) };
        const rowProps = getRowProps ? getRowProps(row) : {};
        return (
          <div key={item.id} {...rowProps} onClick={() => onRowClick({ original: item })}>
            {item.attributes.visual_components[0]?.properties?.card_title || item.id}
          </div>
        );
      })}
    </div>
  ),
}));
jest.mock('@/components/EnhancedPagination', () => ({
  __esModule: true,
  default: ({ currentPage, handlePageChange }: any) => (
    <div data-testid='pagination'>
      <button onClick={() => handlePageChange(currentPage + 1)}>Next</button>
    </div>
  ),
}));
jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

const mockUseDataAppQueries = useDataAppQueries as jest.MockedFunction<typeof useDataAppQueries>;
const mockUseAPIErrorsToast = useAPIErrorsToast as jest.MockedFunction<typeof useAPIErrorsToast>;
const mockUseFilters = useFilters as jest.MockedFunction<typeof useFilters>;
const mockUseProtectedNavigate = useProtectedNavigate as jest.MockedFunction<
  typeof useProtectedNavigate
>;

const mockAssistantDataApp = {
  id: 1,
  type: 'data-apps',
  attributes: {
    name: 'Test Assistant',
    description: '',
    status: 'active',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
    rendering_type: RENDERING_OPTION_TYPE.ASSISTANT,
    visual_components: [
      {
        properties: {
          field_group: '',
          measure_value: '',
          card_title: 'Test Assistant',
          visual_color: '#000000',
          file_id: 'file-1',
        },
        feedback_config: {
          feedback_enabled: false,
          feedback_method: null,
          feedback_title: '',
        },
      },
    ],
    meta_data: {
      rendering_type: 'assistant',
    },
    data_app_token: 'token-123',
  },
};

const mockDataApp = {
  id: 2,
  type: 'data-apps',
  attributes: {
    name: 'Test Data App',
    description: '',
    status: 'active',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
    rendering_type: RENDERING_OPTION_TYPE.NO_CODE,
    visual_components: [
      {
        properties: {
          field_group: '',
          measure_value: '',
          card_title: 'Test Data App',
          visual_color: '#000000',
          file_id: 'file-2',
        },
        feedback_config: {
          feedback_enabled: false,
          feedback_method: null,
          feedback_title: '',
        },
      },
    ],
    meta_data: {
      rendering_type: 'data_app',
    },
    data_app_token: 'token-456',
  },
};

describe('AssistantsList', () => {
  const mockNavigate = jest.fn();
  const mockUpdateFilters = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();

    mockUseAPIErrorsToast.mockReturnValue(mockApiErrorToast);
    mockUseProtectedNavigate.mockReturnValue(mockNavigate);
    mockUseFilters.mockReturnValue({
      filters: {
        page: '1',
        rendering_type: 'assistant',
      },
      updateFilters: mockUpdateFilters,
    } as any);

    mockUseDataAppQueries.mockReturnValue({
      useGetDataApps: jest.fn().mockReturnValue({
        data: {
          data: [mockAssistantDataApp],
          links: {
            first: 'http://localhost?page=1',
            last: 'http://localhost?page=5',
            prev: null,
            next: 'http://localhost?page=2',
          },
        },
        isLoading: false,
      }),
    } as any);
  });

  describe('Component Rendering', () => {
    it('should render AssistantsList with correct title and description', () => {
      renderWithProviders(<AssistantsList />);

      expect(screen.getByText('Chat Assistants')).toBeInTheDocument();
      expect(
        screen.getByText(
          'Access and interact with your standalone chat assistants created using AI workflows and Data Apps.',
        ),
      ).toBeInTheDocument();
    });

    it('should render data table when assistants exist', () => {
      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('data-table')).toBeInTheDocument();
      const row = screen.getByTestId('assistant-list-row-1');
      expect(row).toBeInTheDocument();
      expect(row).toHaveAttribute('data-assistant-card-title', 'Test Assistant');
    });

    it('should render NoAssistants when no assistants exist', () => {
      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: {
            data: [],
          },
          isLoading: false,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('no-assistants')).toBeInTheDocument();
    });

    it('should show loader when data is fetching', () => {
      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: null,
          isLoading: true,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('loader')).toBeInTheDocument();
    });
  });

  describe('Data Filtering', () => {
    it('should filter only assistant rendering type', () => {
      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: {
            data: [mockAssistantDataApp, mockDataApp],
          },
          isLoading: false,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('assistant-list-row-1')).toBeInTheDocument();
      expect(screen.queryByTestId('assistant-list-row-2')).not.toBeInTheDocument();
    });

    it('should handle empty data array', () => {
      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: {
            data: [],
          },
          isLoading: false,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('no-assistants')).toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('should show error toast when data has errors', () => {
      const errorData = {
        errors: [{ detail: 'Error message' }],
      };

      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: errorData,
          isLoading: false,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(mockApiErrorToast).toHaveBeenCalledWith(errorData.errors);
    });
  });

  describe('Row Click Navigation', () => {
    it('should navigate to assistant detail when row is clicked', () => {
      renderWithProviders(<AssistantsList />);

      const row = screen.getByTestId('assistant-list-row-1');
      fireEvent.click(row);

      expect(mockNavigate).toHaveBeenCalledWith({
        to: '1',
        location: 'data_app',
        action: expect.any(String),
      });
    });
  });

  describe('Pagination', () => {
    it('should render pagination when links exist', () => {
      renderWithProviders(<AssistantsList />);

      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });

    it('should not render pagination when links do not exist', () => {
      mockUseDataAppQueries.mockReturnValue({
        useGetDataApps: jest.fn().mockReturnValue({
          data: {
            data: [mockAssistantDataApp],
            links: null,
          },
          isLoading: false,
        }),
      } as any);

      renderWithProviders(<AssistantsList />);

      expect(screen.queryByTestId('pagination')).not.toBeInTheDocument();
    });

    it('should update filters when page changes', () => {
      renderWithProviders(<AssistantsList />);

      const nextButton = screen.getByText('Next');
      fireEvent.click(nextButton);

      expect(mockUpdateFilters).toHaveBeenCalledWith({
        page: '2',
        rendering_type: 'assistant',
      });
    });
  });

  describe('Filters', () => {
    it('should initialize with correct filters', () => {
      renderWithProviders(<AssistantsList />);

      expect(mockUseFilters).toHaveBeenCalledWith({
        page: '1',
        rendering_type: 'assistant',
      });
    });
  });
});
