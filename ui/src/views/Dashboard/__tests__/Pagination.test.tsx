import { render, screen, fireEvent } from '@testing-library/react';
import Pagination from '@/components/Pagination';
import { expect } from '@jest/globals';

describe('Pagination Component', () => {
  const handlePrevPage = jest.fn();
  const handleNextPage = jest.fn();

  beforeEach(() => {
    render(
      <Pagination
        currentPage={1}
        isNextPageEnabled={true}
        isPrevPageEnabled={true}
        handlePrevPage={handlePrevPage}
        handleNextPage={handleNextPage}
      />,
    );
  });

  it('should render the current page number', () => {
    expect(screen.getByText('1'));
  });

  it('should render the previous and next page buttons', () => {
    expect(screen.getAllByRole('button')).toHaveLength(2);
  });

  it('should call handlePrevPage when the previous button is clicked', () => {
    const prevButton = screen.getAllByRole('button')[0];
    fireEvent.click(prevButton);
    expect(handlePrevPage).toHaveBeenCalledTimes(1);
  });

  it('should call handleNextPage when the next button is clicked', () => {
    const nextButton = screen.getAllByRole('button')[1];
    fireEvent.click(nextButton);
    expect(handleNextPage).toHaveBeenCalledTimes(1);
  });
});
