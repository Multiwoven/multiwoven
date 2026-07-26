import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import ListResources from '../ListResources';
import { HostedStoreTemplateActionState } from '../types';

// Mock hooks
const mockNavigate = jest.fn();
const mockUseGetHostedDBTemplates = jest.fn();
const mockMutateAsync = jest.fn();
const mockApiErrorToast = jest.fn();

jest.mock('@/enterprise/hooks/useProtectedNavigate', () => ({
  __esModule: true,
  default: () => mockNavigate,
}));

jest.mock('@/enterprise/hooks/queries/useHostedStoreQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetHostedDBTemplates: mockUseGetHostedDBTemplates,
  }),
}));

jest.mock('@/enterprise/hooks/mutations/useHostedStoreMutations', () => ({
  __esModule: true,
  default: () => ({
    createHostedDataStoreMutation: {
      mutateAsync: mockMutateAsync,
      isPending: false,
    },
  }),
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/assets/images/ais-icon.svg', () => 'ais-icon.svg');

describe('ListResources', () => {
  const mockTemplate = {
    id: 'template-1',
    template_id: 'vector_store_hosted_connector',
    name: 'Vector Store',
    description: 'An all-in-one database solution',
    database_type: 'vector_db',
    action_state: HostedStoreTemplateActionState.Setup,
    linked: false,
    linked_data_store_id: null,
  };

  const mockLinkedTemplate = {
    id: 'template-2',
    template_id: 'vector_store_hosted_connector',
    name: 'Vector Store',
    description: 'An all-in-one database solution',
    database_type: 'vector_db',
    action_state: HostedStoreTemplateActionState.Manage,
    linked: true,
    linked_data_store_id: 'store-123',
  };

  const mockComingSoonTemplate = {
    id: 'template-3',
    template_id: 'future_connector',
    name: 'Future DB',
    description: 'Coming soon feature',
    database_type: 'future_db',
    action_state: HostedStoreTemplateActionState.ComingSoon,
    linked: false,
    linked_data_store_id: null,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseGetHostedDBTemplates.mockReturnValue({
      data: { data: [mockTemplate] },
      isLoading: false,
    });
  });

  describe('Loading State', () => {
    it('renders loader while data is loading', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: null,
        isLoading: true,
      });

      render(<ListResources />);

      expect(screen.getByTestId('loader')).toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('calls apiErrorToast when hostedDBTemplates has errors', () => {
      const errors = [{ message: 'Failed to fetch templates' }];
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { errors },
        isLoading: false,
      });

      render(<ListResources />);

      expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
    });
  });

  describe('ResourceCard Rendering', () => {
    it('renders resource cards for each template', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockTemplate, mockLinkedTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      expect(screen.getAllByText('Vector Store')).toHaveLength(2);
    });

    it('displays template title and description', () => {
      render(<ListResources />);

      expect(screen.getByText('Vector Store')).toBeInTheDocument();
      expect(screen.getByText('An all-in-one database solution')).toBeInTheDocument();
    });

    it('shows Setup button for unlinked templates', () => {
      render(<ListResources />);

      expect(screen.getByRole('button', { name: 'Setup' })).toBeInTheDocument();
    });

    it('sets a per-template data-testid on resource card CTAs', () => {
      render(<ListResources />);

      expect(
        screen.getByTestId('resource-card-cta-vector_store_hosted_connector'),
      ).toBeInTheDocument();
    });

    it('shows Manage button for linked templates', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockLinkedTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      expect(screen.getByRole('button', { name: 'Manage' })).toBeInTheDocument();
    });

    it('shows Coming soon badge for coming soon templates', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockComingSoonTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      expect(screen.getByText('Coming soon')).toBeInTheDocument();
    });

    it('disables button for coming soon templates', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockComingSoonTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      const button = screen.getByRole('button', { name: 'Setup' });
      expect(button).toBeDisabled();
    });
  });

  describe('Navigation', () => {
    it('navigates to manage page when clicking on linked template', async () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockLinkedTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      const manageButton = screen.getByRole('button', { name: 'Manage' });
      fireEvent.click(manageButton);

      await waitFor(() => {
        expect(mockNavigate).toHaveBeenCalledWith({
          to: 'manage/vector-store/store-123',
          location: 'alerts',
          action: 'update',
        });
      });
    });
  });

  describe('Store Creation', () => {
    it('creates new store and navigates when clicking Setup on unlinked template', async () => {
      mockMutateAsync.mockResolvedValue({
        data: { id: 'new-store-456' },
      });

      render(<ListResources />);

      const setupButton = screen.getByRole('button', { name: 'Setup' });
      fireEvent.click(setupButton);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          hosted_data_store: {
            name: 'Vector Store',
            database_type: 'vector_db',
            description: 'An all-in-one database solution',
            template_id: 'vector_store_hosted_connector',
          },
        });
      });

      await waitFor(() => {
        expect(mockNavigate).toHaveBeenCalledWith({
          to: 'manage/vector-store/new-store-456',
          location: 'alerts',
          action: 'update',
        });
      });
    });

    it('shows error toast when store creation fails', async () => {
      const errors = [{ message: 'Failed to create store' }];
      mockMutateAsync.mockResolvedValue({ errors });

      render(<ListResources />);

      const setupButton = screen.getByRole('button', { name: 'Setup' });
      fireEvent.click(setupButton);

      await waitFor(() => {
        expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
      });

      expect(mockNavigate).not.toHaveBeenCalled();
    });

    it('does not navigate when store creation returns no id', async () => {
      mockMutateAsync.mockResolvedValue({ data: {} });

      render(<ListResources />);

      const setupButton = screen.getByRole('button', { name: 'Setup' });
      fireEvent.click(setupButton);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalled();
      });

      expect(mockNavigate).not.toHaveBeenCalled();
    });
  });

  describe('Empty State', () => {
    it('renders empty container when no templates exist', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [] },
        isLoading: false,
      });

      render(<ListResources />);

      expect(screen.queryByRole('button')).not.toBeInTheDocument();
    });

    it('handles undefined data gracefully', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: undefined },
        isLoading: false,
      });

      render(<ListResources />);

      expect(screen.queryByRole('button')).not.toBeInTheDocument();
    });
  });

  describe('Multiple Templates', () => {
    it('renders all template types correctly', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [mockTemplate, mockLinkedTemplate, mockComingSoonTemplate] },
        isLoading: false,
      });

      render(<ListResources />);

      // Two "Vector Store" titles and one "Future DB"
      expect(screen.getAllByText('Vector Store')).toHaveLength(2);
      expect(screen.getByText('Future DB')).toBeInTheDocument();

      // One Setup, one Manage, and one disabled Setup button
      expect(screen.getByRole('button', { name: 'Manage' })).toBeInTheDocument();
      const setupButtons = screen.getAllByRole('button', { name: 'Setup' });
      expect(setupButtons).toHaveLength(2);
      expect(setupButtons[1]).toBeDisabled(); // Coming soon template
    });
  });
});
