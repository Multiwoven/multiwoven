import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import VersionPreviewBanner from '../VersionPreviewBanner';
import { ChakraProvider } from '@chakra-ui/react';

// Mock react-icons - uses automatic mock from src/__mocks__/react-icons/fi.tsx
jest.mock('react-icons/fi');

describe('VersionPreviewBanner', () => {
  const mockOnCancel = jest.fn();
  const mockOnShowChanges = jest.fn();

  const renderComponent = (versionNumber: string = 'v1') => {
    return render(
      <ChakraProvider>
        <VersionPreviewBanner
          versionLabel={versionNumber}
          onCancel={mockOnCancel}
          onPrimaryAction={mockOnShowChanges}
          primaryActionLabel='Show Version Changes'
        />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render the banner', () => {
      renderComponent();
      expect(screen.getByText('Previewing version')).toBeInTheDocument();
    });

    it('should render the eye icon', () => {
      renderComponent();
      expect(screen.getByTestId('fi-eye')).toBeInTheDocument();
    });

    it('should render the version number', () => {
      renderComponent('v5');
      expect(screen.getByText('v5')).toBeInTheDocument();
    });

    it('should render Cancel button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    });

    it('should render Show Version Changes button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Show Version Changes' })).toBeInTheDocument();
    });

    it('should render Show Version Changes button with data-testid workflow-version-show-changes-button', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-version-show-changes-button')).toBeInTheDocument();
    });
  });

  describe('User Interactions', () => {
    it('should call onCancel when Cancel button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
      expect(mockOnCancel).toHaveBeenCalledTimes(1);
    });

    it('should call onShowChanges when Show Version Changes button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Show Version Changes' }));
      expect(mockOnShowChanges).toHaveBeenCalledTimes(1);
    });
  });

  describe('Version Number Display', () => {
    it('should display version number v1', () => {
      renderComponent('v1');
      expect(screen.getByText('v1')).toBeInTheDocument();
    });

    it('should display version number v10', () => {
      renderComponent('v10');
      expect(screen.getByText('v10')).toBeInTheDocument();
    });

    it('should display version number v100', () => {
      renderComponent('v100');
      expect(screen.getByText('v100')).toBeInTheDocument();
    });

    it('should handle empty version number', () => {
      renderComponent('');
      // The version badge should still render, just empty
      expect(screen.getByText('Previewing version')).toBeInTheDocument();
    });
  });

  describe('Styling', () => {
    it('should have correct positioning styles', () => {
      const { container } = renderComponent();
      const banner = container.firstChild as HTMLElement;

      // Check that the banner has absolute positioning
      expect(banner).toHaveStyle({ position: 'absolute' });
    });
  });
});
