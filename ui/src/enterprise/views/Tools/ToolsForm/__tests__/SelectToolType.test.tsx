import { screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import SelectToolType from '../SelectToolType';
import { getToolDefinition } from '@/enterprise/services/tools';
import useSteppedForm from '@/stores/useSteppedForm';
import useCustomToast from '@/hooks/useCustomToast';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ToolDefinitionTemplate } from '../../ToolsList/types';
import { ApiResponse } from '@/services/common';
import { CustomToastStatus } from '@/components/Toast';
import {
  mockHandleMoveForward,
  mockSaveConnectorFormData,
  mockShowToast,
  mockToolDefinitionsResponse,
} from '../../../../../../__mocks__/toolMocks';
import { renderWithProviders, createTestQueryClient } from '@/utils/testUtils';

jest.mock('@/enterprise/services/tools', () => ({
  getToolDefinitions: jest.fn(),
  getToolDefinition: jest.fn(),
}));

jest.mock('@/stores/useSteppedForm');
jest.mock('@/hooks/useCustomToast');
jest.mock('@/hooks/useQueryWrapper');

const mockGetToolDefinition = getToolDefinition as jest.MockedFunction<typeof getToolDefinition>;
const mockUseSteppedForm = useSteppedForm as jest.MockedFunction<typeof useSteppedForm>;
const mockUseCustomToast = useCustomToast as jest.MockedFunction<typeof useCustomToast>;
const mockUseQueryWrapper = useQueryWrapper as jest.MockedFunction<typeof useQueryWrapper>;

const queryClient = createTestQueryClient();

const renderSelectToolType = () => {
  return renderWithProviders(<SelectToolType />, { queryClient });
};

describe('SelectToolType', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    mockUseSteppedForm.mockReturnValue({
      handleMoveForward: mockHandleMoveForward,
      stepInfo: { formKey: 'tool' },
      saveConnectorFormData: mockSaveConnectorFormData,
    } as any);

    mockUseCustomToast.mockReturnValue(mockShowToast as any);

    mockUseQueryWrapper.mockReturnValue({
      data: mockToolDefinitionsResponse,
      isLoading: false,
      error: null,
      refetch: jest.fn(),
    } as any);
  });

  it('should render loading state', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: undefined,
      isLoading: true,
      error: null,
      refetch: jest.fn(),
    } as any);

    renderSelectToolType();

    // When loading, the component should render Loader
    // The query wrapper should have been called with getToolDefinitions
    expect(mockUseQueryWrapper).toHaveBeenCalledWith(
      ['tool-definitions'],
      expect.any(Function),
      expect.objectContaining({
        refetchOnMount: true,
        refetchOnWindowFocus: false,
      }),
    );
  });

  it('should render all tabs', () => {
    renderSelectToolType();

    expect(screen.getByText('All Tools')).toBeInTheDocument();
    expect(screen.getByText('AI Squared')).toBeInTheDocument();
    expect(screen.getByText('Custom')).toBeInTheDocument();
  });

  it('passes tools-select-definition test ids to connector tiles', () => {
    renderSelectToolType();
    expect(screen.getByTestId('tools-select-definition-tool-1')).toBeInTheDocument();
    expect(screen.getByTestId('tools-select-definition-tool-2')).toBeInTheDocument();
    expect(screen.getByTestId('tools-select-definition-tool-3')).toBeInTheDocument();
  });

  it('should filter connectors by custom category when Custom tab is clicked', () => {
    renderSelectToolType();

    const customTab = screen.getByText('Custom');
    fireEvent.click(customTab);

    // Should show only custom tools
    expect(screen.getByText('Tool 2')).toBeInTheDocument();
  });

  it('should filter connectors by ai_squared category when AI Squared tab is clicked', () => {
    renderSelectToolType();

    const aiSquaredTab = screen.getByText('AI Squared');
    fireEvent.click(aiSquaredTab);

    // Should show only AI Squared tools
    expect(screen.getByText('Tool 1')).toBeInTheDocument();
    expect(screen.getByText('Tool 3')).toBeInTheDocument();
  });

  it('should show all tools when All Tools tab is clicked', () => {
    renderSelectToolType();

    const allTab = screen.getByText('All Tools');
    fireEvent.click(allTab);

    // Should show all tools
    expect(screen.getByText('Tool 1')).toBeInTheDocument();
    expect(screen.getByText('Tool 2')).toBeInTheDocument();
    expect(screen.getByText('Tool 3')).toBeInTheDocument();
  });

  it('should show empty state when no tools are available', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: { data: [], status: 200 } as ApiResponse<ToolDefinitionTemplate[]>,
      isLoading: false,
      error: null,
      refetch: jest.fn(),
    } as any);

    renderSelectToolType();

    expect(screen.getByText('No tools available yet')).toBeInTheDocument();
  });

  it('should save tool metadata and move forward when tool is selected', async () => {
    const mockDefinition = {
      $id: 'tool-1',
      title: 'Tool 1',
      category: 'ai_squared',
      icon: 'icon1',
    };

    mockGetToolDefinition.mockResolvedValue({
      data: mockDefinition,
    } as ApiResponse<ToolDefinitionTemplate>);

    renderSelectToolType();

    // Wait for tools to render, then click on a tool
    await waitFor(() => {
      expect(screen.getByText('Tool 1')).toBeInTheDocument();
    });

    // Find and click the connector item (this may need adjustment based on ConnectorsGridItem implementation)
    const tool1 = screen.getByText('Tool 1');
    fireEvent.click(tool1);

    await waitFor(() => {
      expect(mockGetToolDefinition).toHaveBeenCalledWith('tool-1');
      expect(mockSaveConnectorFormData).toHaveBeenCalledWith('tool-1', 'metadata', {
        category: 'ai_squared',
        icon: 'icon1',
        definition_id: 'tool-1',
      });
      expect(mockHandleMoveForward).toHaveBeenCalledWith('tool', 'tool-1');
    });
  });

  it('should show error toast when tool definition fetch fails', async () => {
    mockGetToolDefinition.mockRejectedValue(new Error('Failed to fetch'));

    renderSelectToolType();

    await waitFor(() => {
      expect(screen.getByText('Tool 1')).toBeInTheDocument();
    });

    const tool1 = screen.getByText('Tool 1');
    fireEvent.click(tool1);

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith({
        status: CustomToastStatus.Error,
        title: 'Error',
        description: 'Failed to fetch tool definition. Using default values.',
        position: 'bottom-right',
        isClosable: true,
      });
    });
  });

  it('should use default category when tool definition has no category', async () => {
    const mockDefinition = {
      $id: 'tool-1',
      title: 'Tool 1',
      icon: 'icon1',
    };

    mockGetToolDefinition.mockResolvedValue({
      data: mockDefinition,
    } as ApiResponse<ToolDefinitionTemplate>);

    renderSelectToolType();

    await waitFor(() => {
      expect(screen.getByText('Tool 1')).toBeInTheDocument();
    });

    const tool1 = screen.getByText('Tool 1');
    fireEvent.click(tool1);

    await waitFor(() => {
      expect(mockSaveConnectorFormData).toHaveBeenCalledWith('tool-1', 'metadata', {
        category: 'custom',
        icon: 'icon1',
        definition_id: 'tool-1',
      });
    });
  });

  it('should not move forward if stepInfo formKey is not available', async () => {
    mockUseSteppedForm.mockReturnValue({
      handleMoveForward: mockHandleMoveForward,
      stepInfo: null,
      saveConnectorFormData: mockSaveConnectorFormData,
    } as any);

    const mockDefinition = {
      $id: 'tool-1',
      title: 'Tool 1',
      category: 'ai_squared',
      icon: 'icon1',
    };

    mockGetToolDefinition.mockResolvedValue({
      data: mockDefinition,
    } as ApiResponse<ToolDefinitionTemplate>);

    renderSelectToolType();

    await waitFor(() => {
      expect(screen.getByText('Tool 1')).toBeInTheDocument();
    });

    const tool1 = screen.getByText('Tool 1');
    fireEvent.click(tool1);

    await waitFor(() => {
      expect(mockGetToolDefinition).toHaveBeenCalled();
      expect(mockSaveConnectorFormData).toHaveBeenCalled();
    });

    expect(mockHandleMoveForward).not.toHaveBeenCalled();
  });

  it('should call getToolDefinitions when query executes', async () => {
    // The query wrapper should call getToolDefinitions
    // This is verified through the useQueryWrapper mock setup
    renderSelectToolType();

    // Verify that useQueryWrapper was called with getToolDefinitions
    await waitFor(() => {
      expect(mockUseQueryWrapper).toHaveBeenCalledWith(
        ['tool-definitions'],
        expect.any(Function),
        expect.objectContaining({
          refetchOnMount: true,
          refetchOnWindowFocus: false,
        }),
      );
    });
  });
});
