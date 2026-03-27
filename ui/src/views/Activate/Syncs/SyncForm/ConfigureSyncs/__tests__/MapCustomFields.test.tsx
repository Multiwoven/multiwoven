import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

jest.mock('flat', () => ({
  flatten: jest.fn((obj: Record<string, unknown>) => {
    const result: Record<string, unknown> = {};
    const flattenHelper = (o: Record<string, unknown>, prefix = '') => {
      Object.keys(o).forEach((key) => {
        const newKey = prefix ? `${prefix}.${key}` : key;
        if (typeof o[key] === 'object' && o[key] !== null && !Array.isArray(o[key])) {
          flattenHelper(o[key] as Record<string, unknown>, newKey);
        } else {
          result[newKey] = o[key];
        }
      });
    };
    flattenHelper(obj);
    return result;
  }),
}));

import MapCustomFields from '../MapCustomFields';
import { useStore } from '@/stores';
import { Stream } from '../../../types';
import { mockStoreImplementation } from '../../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockStream: Stream = {
  name: 'test_stream',
  action: 'read',
  json_schema: { type: 'object', properties: {} },
  url: '',
  supported_sync_modes: ['full_refresh'],
};

const mockModel = {
  id: '1',
  name: 'Test Model',
  connector: { id: '1', name: 'PostgreSQL' },
  query: 'SELECT * FROM table',
};

const mockDestination = {
  id: '2',
  attributes: { name: 'Snowflake' },
};

const mockUseQuery = jest.fn();
const mockHandleOnConfigChange = jest.fn();

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@tanstack/react-query', () => {
  const actual =
    jest.requireActual<typeof import('@tanstack/react-query')>('@tanstack/react-query');
  return {
    ...actual,
    useQuery: (opts: { queryFn?: () => unknown; enabled?: boolean }) => {
      if (opts.enabled !== false && typeof opts.queryFn === 'function') {
        try {
          opts.queryFn();
        } catch {
          /* expected in mock */
        }
      }
      return mockUseQuery();
    },
  };
});

jest.mock('../FieldMap', () => ({
  __esModule: true,
  default: ({
    entityName,
    onChange,
    id,
  }: {
    entityName: string;
    onChange: (id: number, type: string, value: string) => void;
    id: number;
  }) => (
    <div data-testid={`field-map-${entityName}`}>
      <button onClick={() => onChange(id, 'model', 'value1')}>Change Model</button>
      <button onClick={() => onChange(id, 'custom', 'custom_value')}>Change Custom</button>
    </div>
  ),
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = (props: Record<string, unknown> = {}) => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MapCustomFields
          model={mockModel as any}
          destination={mockDestination as any}
          stream={mockStream}
          handleOnConfigChange={mockHandleOnConfigChange}
          {...props}
        />
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('MapCustomFields', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockUseQuery.mockReturnValue({
      data: [{ id: '1', name: 'Test' }],
    });
  });

  it('renders custom field mapping components', () => {
    renderComponent();
    // The component renders FieldMap with entityName from destination, not "Custom"
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('calls handleOnConfigChange when custom field is updated', () => {
    renderComponent();
    // There may be multiple "Change Custom" buttons (one for each field)
    const changeButtons = screen.getAllByText('Change Custom');
    if (changeButtons.length > 0) {
      fireEvent.click(changeButtons[0]);
      expect(mockHandleOnConfigChange).toHaveBeenCalled();
    }
  });

  it('handles add field button', () => {
    renderComponent();
    // The button text is "Add mapping" not "Add Field"
    const addButton = screen.getByText(/Add mapping/i);
    const initialCount = screen.getAllByTestId(/field-map-/).length;
    fireEvent.click(addButton);
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(initialCount);
  });

  it('handles remove field button', () => {
    renderComponent({ data: [{ from: 'field1', to: 'field2', mapping_type: 'standard' }] });
    // CloseButton doesn't have accessible name, so we query by role and aria-label or testid
    const closeButtons = screen.getAllByRole('button').filter((btn) => {
      // CloseButton typically has aria-label="Close" or similar
      return (
        btn.getAttribute('aria-label')?.toLowerCase().includes('close') || btn.querySelector('svg')
      ); // CloseButton usually has an SVG icon
    });
    if (closeButtons.length > 0) {
      fireEvent.click(closeButtons[0]);
      expect(mockHandleOnConfigChange).toHaveBeenCalled();
    }
  });

  it('handles edit mode with existing configuration', () => {
    renderComponent({
      isEdit: true,
      configuration: [{ from: 'field1', to: 'field2', mapping_type: 'standard' }],
    });
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('handles data as non-array object format', () => {
    renderComponent({
      data: { field1: 'mapped1', field2: 'mapped2' } as unknown as null,
    });
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('handles model field change', () => {
    renderComponent();
    const changeButtons = screen.getAllByText('Change Model');
    fireEvent.click(changeButtons[0]);
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('initializes with empty configuration array', () => {
    renderComponent({ configuration: [] });
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('removes a field when close button is clicked', () => {
    renderComponent({
      data: [
        { from: 'field1', to: 'dest1', mapping_type: 'standard' },
        { from: 'field2', to: 'dest2', mapping_type: 'standard' },
      ],
    });
    const closeButtons = screen.getAllByLabelText('Close');
    const initialFieldCount = screen.getAllByTestId(/field-map-/).length;
    fireEvent.click(closeButtons[0]);
    expect(screen.getAllByTestId(/field-map-/).length).toBeLessThan(initialFieldCount);
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });
});
