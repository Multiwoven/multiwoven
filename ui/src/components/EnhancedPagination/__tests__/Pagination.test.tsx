import { fireEvent, render, screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom';

import Pagination, { PaginationProps } from '../Pagination';

describe('Pagination', () => {
  const mockHandlePageChange = jest.fn();
  const defaultProps: PaginationProps = {
    links: {
      self: 'http://localhost:3000/api/v1/connectors?',
      first: 'http://localhost:3000/api/v1/connectors?page=1&per_page=10',
      prev: null,
      next: 'http://localhost:3000/api/v1/connectors?page=2&per_page=10',
      last: 'http://localhost:3000/api/v1/connectors?page=10&per_page=10',
    },
    currentPage: 5,
    handlePageChange: mockHandlePageChange,
  };

  beforeEach(() => {
    mockHandlePageChange.mockClear();
  });

  it('should render correct page numbers for middle page', () => {
    render(<Pagination {...defaultProps} />);
    expect(screen.getByTestId('page-number-1')).toBeTruthy();
    expect(screen.getByTestId('page-number-5')).toBeTruthy();
    expect(screen.getByTestId('page-number-10')).toBeTruthy();
  });

  it('should render correct page numbers for first page', () => {
    render(<Pagination {...defaultProps} currentPage={1} />);
    expect(screen.getByTestId('page-number-1')).toBeTruthy();
    expect(screen.getByTestId('page-number-10')).toBeTruthy();
    expect(screen.queryByTestId('page-number-5')).not.toBeTruthy();
  });

  it('should render correct page numbers for last page', () => {
    render(<Pagination {...defaultProps} currentPage={10} />);
    expect(screen.getByTestId('page-number-1')).toBeTruthy();
    expect(screen.getByTestId('page-number-10')).toBeTruthy();
  });

  it('should call handlePageChange with correct page number when a page number is clicked', () => {
    render(<Pagination {...defaultProps} />);
    const pageButton = screen.getByTestId('page-number-1');
    fireEvent.click(pageButton);
    expect(mockHandlePageChange).toHaveBeenCalledWith(1);
  });

  it('should disable first and previous buttons on first page', () => {
    render(<Pagination {...defaultProps} currentPage={1} />);

    expect(screen.getByTestId('page-change-first')).toHaveProperty('disabled', true);
    expect(screen.getByTestId('page-change-previous')).toHaveProperty('disabled', true);
  });

  it('should disable next and last buttons on last page', () => {
    render(<Pagination {...defaultProps} currentPage={10} />);

    expect(screen.getByTestId('page-change-next')).toHaveProperty('disabled', true);
    expect(screen.getByTestId('page-change-last')).toHaveProperty('disabled', true);
  });

  it('should call handlePageChange with correct page number when navigation buttons are clicked', () => {
    render(<Pagination {...defaultProps} />);
    fireEvent.click(screen.getByTestId('page-change-first'));
    expect(mockHandlePageChange).toHaveBeenCalledWith(1);

    fireEvent.click(screen.getByTestId('page-change-previous'));
    expect(mockHandlePageChange).toHaveBeenCalledWith(4);

    fireEvent.click(screen.getByTestId('page-change-next'));
    expect(mockHandlePageChange).toHaveBeenCalledWith(6);

    fireEvent.click(screen.getByTestId('page-change-last'));
    expect(mockHandlePageChange).toHaveBeenCalledWith(10);
  });

  it('should render ellipsis correctly', () => {
    render(<Pagination {...defaultProps} />);
    const ellipses = screen.getAllByText('...');
    expect(ellipses).toHaveLength(2);
  });
});
