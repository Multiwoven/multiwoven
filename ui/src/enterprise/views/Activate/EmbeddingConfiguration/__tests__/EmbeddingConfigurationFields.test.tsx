import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import EmbeddingConfigurationFields from '../EmbeddingConfigurationFields';
import { EmbeddingConfigurationType } from '@/enterprise/services/types';

const mockConfigurations: EmbeddingConfigurationType[] = [
  {
    id: '1',
    type: 'embedding_configuration',
    attributes: {
      mode: 'openai',
      models: ['text-embedding-ada-002', 'text-embedding-3-small'],
    },
  },
];

const renderEmbeddingConfigurationFields = (props = {}) => {
  const defaultProps = {
    configurations: mockConfigurations,
    embeddingConfig: { mode: '', model: '', api_key: '' },
    setEmbeddingConfig: jest.fn(),
    ...props,
  };

  return render(
    <ChakraProvider>
      <EmbeddingConfigurationFields {...defaultProps} />
    </ChakraProvider>,
  );
};

describe('EmbeddingConfigurationFields', () => {
  const mockSetEmbeddingConfig = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render embedding mode select field', () => {
    renderEmbeddingConfigurationFields();
    expect(screen.getByText('Embedding Provider')).toBeInTheDocument();
    expect(screen.getByText('Select Embedding Provider')).toBeInTheDocument();
  });

  it('should render embedding model select field', () => {
    renderEmbeddingConfigurationFields();
    expect(screen.getByText('Embedding Model')).toBeInTheDocument();
    expect(screen.getByText('Select Embedding Model')).toBeInTheDocument();
  });

  it('should render API key input field', () => {
    renderEmbeddingConfigurationFields();
    expect(screen.getByText('API Key')).toBeInTheDocument();
    expect(screen.getByTestId('hidden-input-field')).toBeInTheDocument();
  });

  it('should forward embeddingApiKeyTestId to the API key input data-testid', () => {
    renderEmbeddingConfigurationFields({ embeddingApiKeyTestId: 'create-kb-embedding-key' });
    expect(screen.getByTestId('create-kb-embedding-key')).toBeInTheDocument();
    expect(screen.queryByTestId('hidden-input-field')).not.toBeInTheDocument();
  });

  it('should render all mode options', () => {
    renderEmbeddingConfigurationFields();
    expect(screen.getByText('openai')).toBeInTheDocument();
  });

  it('should update model options when mode is selected', () => {
    renderEmbeddingConfigurationFields({ setEmbeddingConfig: mockSetEmbeddingConfig });

    const modeSelect = screen.getAllByTestId('select-field')[0];
    fireEvent.change(modeSelect, { target: { value: 'openai' } });

    expect(mockSetEmbeddingConfig).toHaveBeenCalled();
  });

  it('should display model options for selected mode', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: { mode: 'openai', model: '', api_key: '' },
    });

    // Model options should be available
    const modelSelect = screen.getAllByTestId('select-field')[1];
    expect(modelSelect).toBeInTheDocument();
  });

  it('should call setEmbeddingConfig when mode is changed', () => {
    renderEmbeddingConfigurationFields({ setEmbeddingConfig: mockSetEmbeddingConfig });

    const modeSelect = screen.getAllByTestId('select-field')[0];
    fireEvent.change(modeSelect, { target: { value: 'openai' } });

    expect(mockSetEmbeddingConfig).toHaveBeenCalledWith(
      expect.objectContaining({ mode: 'openai' }),
    );
  });

  it('should call setEmbeddingConfig when model is changed', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: { mode: 'openai', model: '', api_key: '' },
      setEmbeddingConfig: mockSetEmbeddingConfig,
    });

    const modelSelect = screen.getAllByTestId('select-field')[1];
    fireEvent.change(modelSelect, { target: { value: 'text-embedding-ada-002' } });

    expect(mockSetEmbeddingConfig).toHaveBeenCalledWith(
      expect.objectContaining({ model: 'text-embedding-ada-002' }),
    );
  });

  it('should call setEmbeddingConfig when API key is changed', () => {
    renderEmbeddingConfigurationFields({ setEmbeddingConfig: mockSetEmbeddingConfig });

    const apiKeyInput = screen.getByTestId('hidden-input-field');
    fireEvent.change(apiKeyInput, { target: { value: 'test-api-key' } });

    expect(mockSetEmbeddingConfig).toHaveBeenCalledWith(
      expect.objectContaining({ api_key: 'test-api-key' }),
    );
  });

  it('should disable all fields when disabled is true', () => {
    renderEmbeddingConfigurationFields({ disabled: true });

    const modeSelect = screen.getAllByTestId('select-field')[0];
    const modelSelect = screen.getAllByTestId('select-field')[1];
    const apiKeyInput = screen.getByTestId('hidden-input-field');

    expect(modeSelect).toBeDisabled();
    expect(modelSelect).toBeDisabled();
    expect(apiKeyInput).toBeDisabled();
  });

  it('should enable all fields when disabled is false', () => {
    renderEmbeddingConfigurationFields({ disabled: false });

    const modeSelect = screen.getAllByTestId('select-field')[0];
    const modelSelect = screen.getAllByTestId('select-field')[1];
    const apiKeyInput = screen.getByTestId('hidden-input-field');

    expect(modeSelect).not.toBeDisabled();
    expect(modelSelect).not.toBeDisabled();
    expect(apiKeyInput).not.toBeDisabled();
  });

  it('should render in row layout when showAsList is false', () => {
    const { container } = renderEmbeddingConfigurationFields({ showAsList: false });
    // Verify the component renders correctly
    expect(screen.getByText('Embedding Provider')).toBeInTheDocument();
    expect(screen.getByText('Embedding Model')).toBeInTheDocument();
    // Check for flex containers (Chakra Box components render as divs with flex styles)
    const flexContainers = Array.from(container.querySelectorAll('div')).filter((el) => {
      const style = window.getComputedStyle(el);
      return style.display === 'flex' && style.flexDirection === 'row';
    });
    expect(flexContainers.length).toBeGreaterThan(0);
  });

  it('should render in column layout when showAsList is true', () => {
    const { container } = renderEmbeddingConfigurationFields({ showAsList: true });
    // Verify the component renders correctly
    expect(screen.getByText('Embedding Provider')).toBeInTheDocument();
    expect(screen.getByText('Embedding Model')).toBeInTheDocument();
    // Check for flex containers with column layout
    const flexContainers = Array.from(container.querySelectorAll('div')).filter((el) => {
      const style = window.getComputedStyle(el);
      return style.display === 'flex' && style.flexDirection === 'column';
    });
    expect(flexContainers.length).toBeGreaterThan(0);
  });

  it('should display selected mode value', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: { mode: 'openai', model: '', api_key: '' },
    });

    const modeSelect = screen.getAllByTestId('select-field')[0] as HTMLSelectElement;
    expect(modeSelect.value).toBe('openai');
  });

  it('should display selected model value', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: {
        mode: 'openai',
        model: 'text-embedding-ada-002',
        api_key: '',
      },
    });

    const modelSelect = screen.getAllByTestId('select-field')[1] as HTMLSelectElement;
    expect(modelSelect.value).toBe('text-embedding-ada-002');
  });

  it('should display API key value', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: {
        mode: 'openai',
        model: '',
        api_key: 'my-api-key',
      },
    });

    const apiKeyInput = screen.getByTestId('hidden-input-field') as HTMLInputElement;
    expect(apiKeyInput.value).toBe('my-api-key');
  });

  it('should handle empty configurations array', () => {
    renderEmbeddingConfigurationFields({
      configurations: [],
    });

    expect(screen.getByText('Embedding Provider')).toBeInTheDocument();
    expect(screen.getByText('Embedding Model')).toBeInTheDocument();
  });

  it('should preserve existing config values when updating', () => {
    renderEmbeddingConfigurationFields({
      embeddingConfig: {
        mode: 'openai',
        model: 'text-embedding-ada-002',
        api_key: 'existing-key',
      },
      setEmbeddingConfig: mockSetEmbeddingConfig,
    });

    const apiKeyInput = screen.getByTestId('hidden-input-field');
    fireEvent.change(apiKeyInput, { target: { value: 'new-key' } });

    expect(mockSetEmbeddingConfig).toHaveBeenCalledWith({
      mode: 'openai',
      model: 'text-embedding-ada-002',
      api_key: 'new-key',
    });
  });
});
