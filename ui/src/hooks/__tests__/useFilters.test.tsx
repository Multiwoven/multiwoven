import { renderHook } from '@testing-library/react';
import { act } from 'react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter, useSearchParams } from 'react-router-dom';
import useFilters from '../useFilters';

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useSearchParams: jest.fn(),
}));

describe('useFilters hook', () => {
  let mockSetSearchParams: jest.Mock;

  beforeEach(() => {
    mockSetSearchParams = jest.fn();
    (useSearchParams as jest.Mock).mockReturnValue([
      new URLSearchParams('?page=1&per_page=10'),
      mockSetSearchParams,
    ]);
  });

  it('should return default filters when no query params are present', () => {
    const emptyQueryParams = new URLSearchParams();
    (useSearchParams as jest.Mock).mockReturnValue([emptyQueryParams, mockSetSearchParams]);
    const { result } = renderHook(
      () => useFilters<{ page: string; per_page: string }>({ page: '1', per_page: '10' }),
      {
        wrapper: MemoryRouter,
      },
    );
    expect(result.current.filters).toEqual({ page: '1', per_page: '10' });
  });

  it('should parse query params correctly', () => {
    const { result } = renderHook(
      () =>
        useFilters<{ page: string; per_page: string; status?: string }>({
          page: '1',
          per_page: '10',
        }),
      {
        wrapper: MemoryRouter,
      },
    );
    expect(result.current.filters).toEqual({ page: '1', per_page: '10' });
  });

  it('should update filters and call setSearchParams', () => {
    const { result } = renderHook(
      () => useFilters<{ page: string; per_page: string }>({ page: '1', per_page: '10' }),
      {
        wrapper: MemoryRouter,
      },
    );

    act(() => {
      result.current.updateFilters({ page: '2', per_page: '20' });
    });

    expect(mockSetSearchParams).toHaveBeenCalledWith({ page: '2', per_page: '20' });
  });

  it('should remove null and undefined values from query params', () => {
    const { result } = renderHook(
      () => useFilters<{ page: string; per_page: string }>({ page: '1', per_page: '10' }),
      {
        wrapper: MemoryRouter,
      },
    );

    act(() => {
      result.current.updateFilters({ page: null as any, per_page: undefined as any });
    });

    expect(mockSetSearchParams).toHaveBeenCalledWith({});
  });

  it('should correctly handle array filters', () => {
    (useSearchParams as jest.Mock).mockReturnValue([
      new URLSearchParams('?tags=react&tags=jest'),
      mockSetSearchParams,
    ]);

    const { result } = renderHook(
      () =>
        useFilters<{ tags: string[]; page: string; per_page: string }>({
          tags: [],
          page: '1',
          per_page: '10',
        }),
      {
        wrapper: MemoryRouter,
      },
    );

    expect(result.current.filters).toEqual({ tags: ['react', 'jest'], page: '1', per_page: '10' });
  });
});
