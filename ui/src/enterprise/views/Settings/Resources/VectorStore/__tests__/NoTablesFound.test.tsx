import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import NoTablesFound from '../NoTablesFound';

jest.mock('@/assets/images/empty-vector-tables.svg', () => 'empty-vector-tables.svg');

describe('NoTablesFound', () => {
  const mockOnOpen = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the title text', () => {
    render(<NoTablesFound onOpen={mockOnOpen} />);

    expect(screen.getByText('No tables created')).toBeInTheDocument();
  });

  it('renders the description text', () => {
    render(<NoTablesFound onOpen={mockOnOpen} />);

    expect(screen.getByText('Define and create a new vector store table')).toBeInTheDocument();
  });

  it('renders Create Table button when showActionButton is true (default)', () => {
    render(<NoTablesFound onOpen={mockOnOpen} />);

    expect(screen.getByRole('button', { name: /create table/i })).toBeInTheDocument();
  });

  it('uses a stable test id on the Create Table action', () => {
    render(<NoTablesFound onOpen={mockOnOpen} />);

    expect(screen.getByTestId('data-store-create-table-button')).toBeInTheDocument();
  });

  it('does not render Create Table button when showActionButton is false', () => {
    render(<NoTablesFound onOpen={mockOnOpen} showActionButton={false} />);

    expect(screen.queryByRole('button', { name: /create table/i })).not.toBeInTheDocument();
  });

  it('calls onOpen when Create Table button is clicked', () => {
    render(<NoTablesFound onOpen={mockOnOpen} />);

    const button = screen.getByRole('button', { name: /create table/i });
    fireEvent.click(button);

    expect(mockOnOpen).toHaveBeenCalledTimes(1);
  });

  it('renders with showActionButton explicitly set to true', () => {
    render(<NoTablesFound onOpen={mockOnOpen} showActionButton={true} />);

    expect(screen.getByRole('button', { name: /create table/i })).toBeInTheDocument();
  });
});
