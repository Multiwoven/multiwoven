import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { ChakraProvider } from '@chakra-ui/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import AddToolButton from '../AddToolButton';

// Mock react-icons
jest.mock('react-icons/fi', () => ({
  FiPlus: () => <span data-testid='fi-plus'>FiPlus</span>,
  FiSettings: () => <span data-testid='fi-settings'>FiSettings</span>,
}));

const renderWithChakra = (ui: React.ReactElement) => render(<ChakraProvider>{ui}</ChakraProvider>);

describe('AddToolButton', () => {
  it('should render button with correct text', () => {
    const onClick = jest.fn();
    renderWithChakra(<AddToolButton onClick={onClick} />);

    expect(screen.getByText('Add a tool')).toBeInTheDocument();
    expect(screen.getByTestId('workflow-tool-add-button')).toBeInTheDocument();
  });

  it('should call onClick when clicked', () => {
    const onClick = jest.fn();
    renderWithChakra(<AddToolButton onClick={onClick} />);

    const button =
      screen.getByText('Add a tool').closest('div[role="button"]') ||
      screen.getByText('Add a tool');
    fireEvent.click(button);

    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('should render FiPlus icon', () => {
    const onClick = jest.fn();
    renderWithChakra(<AddToolButton onClick={onClick} />);

    expect(screen.getByTestId('fi-plus')).toBeInTheDocument();
  });

  it('should render FiSettings icon', () => {
    const onClick = jest.fn();
    renderWithChakra(<AddToolButton onClick={onClick} />);

    expect(screen.getByTestId('fi-settings')).toBeInTheDocument();
  });

  it('should render with correct structure', () => {
    const onClick = jest.fn();
    renderWithChakra(<AddToolButton onClick={onClick} />);

    // Check that all elements are present
    expect(screen.getByText('Add a tool')).toBeInTheDocument();
    expect(screen.getByTestId('fi-plus')).toBeInTheDocument();
    expect(screen.getByTestId('fi-settings')).toBeInTheDocument();
  });
});
