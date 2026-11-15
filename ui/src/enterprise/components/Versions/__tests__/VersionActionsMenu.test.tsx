import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import VersionActionsMenu from '../VersionActionsMenu';
import { ChakraProvider } from '@chakra-ui/react';

// Mock react-icons - uses automatic mock from src/__mocks__/react-icons/fi.tsx
jest.mock('react-icons/fi');

describe('VersionActionsMenu', () => {
  const mockOnEditDescription = jest.fn();
  const mockOnDelete = jest.fn();

  const renderComponent = (
    onEditDescription: () => void = mockOnEditDescription,
    onDelete: () => void = mockOnDelete,
    canDelete: boolean = true,
  ) => {
    return render(
      <ChakraProvider>
        <VersionActionsMenu
          onEditDescription={onEditDescription}
          onDelete={onDelete}
          canDelete={canDelete}
        />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render menu button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Version options' })).toBeInTheDocument();
    });

    it('should render menu items when menu is opened', () => {
      renderComponent();
      const menuButton = screen.getByRole('button', { name: 'Version options' });
      fireEvent.click(menuButton);

      expect(screen.getByText('Edit Description')).toBeInTheDocument();
      expect(screen.getByText('Delete')).toBeInTheDocument();
    });

    it('should render edit icon', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      expect(screen.getByTestId('fi-edit-2')).toBeInTheDocument();
    });

    it('should render delete icon', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      expect(screen.getByTestId('fi-trash-2')).toBeInTheDocument();
    });

    it('should render menu button with data-testid workflow-version-menu-button', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-version-menu-button')).toBeInTheDocument();
    });

    it('should render delete menu item with data-testid workflow-version-delete-button', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('workflow-version-menu-button'));
      expect(screen.getByTestId('workflow-version-delete-button')).toBeInTheDocument();
    });
  });

  describe('Edit Description Action', () => {
    it('should call onEditDescription when Edit Description is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      fireEvent.click(screen.getByText('Edit Description'));

      expect(mockOnEditDescription).toHaveBeenCalledTimes(1);
    });

    it('should stop event propagation when Edit Description is clicked', () => {
      const mockParentClick = jest.fn();

      render(
        <ChakraProvider>
          <div onClick={mockParentClick}>
            <VersionActionsMenu
              onEditDescription={mockOnEditDescription}
              onDelete={mockOnDelete}
              canDelete
            />
          </div>
        </ChakraProvider>,
      );

      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      fireEvent.click(screen.getByText('Edit Description'));

      expect(mockOnEditDescription).toHaveBeenCalled();
      // Parent click should not be triggered due to stopPropagation
    });
  });

  describe('Delete Action', () => {
    it('should call onDelete when Delete is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      fireEvent.click(screen.getByText('Delete'));

      expect(mockOnDelete).toHaveBeenCalledTimes(1);
    });

    it('should disable Delete when canDelete is false', () => {
      renderComponent(mockOnEditDescription, mockOnDelete, false);
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));

      const deleteMenuItem = screen.getByText('Delete');
      expect(deleteMenuItem).toBeInTheDocument();
      const button = deleteMenuItem.closest('button');
      expect(button).toBeDisabled();
    });

    it('should allow Delete when canDelete is true', () => {
      renderComponent(mockOnEditDescription, mockOnDelete, true);
      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));

      const deleteMenuItem = screen.getByText('Delete');
      expect(deleteMenuItem).toBeInTheDocument();
      fireEvent.click(deleteMenuItem);
      expect(mockOnDelete).toHaveBeenCalled();
    });

    it('should stop event propagation when Delete is clicked', () => {
      const mockParentClick = jest.fn();

      render(
        <ChakraProvider>
          <div onClick={mockParentClick}>
            <VersionActionsMenu
              onEditDescription={mockOnEditDescription}
              onDelete={mockOnDelete}
              canDelete
            />
          </div>
        </ChakraProvider>,
      );

      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      fireEvent.click(screen.getByText('Delete'));

      expect(mockOnDelete).toHaveBeenCalled();
    });
  });

  describe('Menu Button Behavior', () => {
    it('should stop event propagation when menu button is clicked', () => {
      const mockParentClick = jest.fn();

      render(
        <ChakraProvider>
          <div onClick={mockParentClick}>
            <VersionActionsMenu
              onEditDescription={mockOnEditDescription}
              onDelete={mockOnDelete}
              canDelete
            />
          </div>
        </ChakraProvider>,
      );

      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));

      // Menu should open but parent click should not be triggered
      expect(screen.getByText('Edit Description')).toBeInTheDocument();
    });
  });

  describe('Default Props', () => {
    it('should disable Delete by default', () => {
      render(
        <ChakraProvider>
          <VersionActionsMenu onEditDescription={mockOnEditDescription} onDelete={mockOnDelete} />
        </ChakraProvider>,
      );

      fireEvent.click(screen.getByRole('button', { name: 'Version options' }));
      const deleteMenuItem = screen.getByText('Delete').closest('button');
      expect(deleteMenuItem).toBeDisabled();
    });
  });
});
