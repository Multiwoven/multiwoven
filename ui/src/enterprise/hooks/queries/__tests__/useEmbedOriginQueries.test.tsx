import { renderHook } from '@testing-library/react';
import useEmbedOriginQueries from '../useEmbedOriginQueries';
import * as queryWrapperModule from '@/hooks/useQueryWrapper';
import { getEmbedOrigins } from '@/enterprise/services/embed-origins';

jest.mock('@/enterprise/services/embed-origins', () => ({
  getEmbedOrigins: jest.fn(),
}));

describe('useEmbedOriginQueries', () => {
  const mockUseQueryWrapper = jest.fn();

  beforeEach(() => {
    jest.spyOn(queryWrapperModule, 'default').mockImplementation(mockUseQueryWrapper);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('calls useQueryWrapper with the scoped embed-origins key', () => {
    renderHook(() => {
      const { useGetEmbedOrigins } = useEmbedOriginQueries();
      useGetEmbedOrigins('workspace');
    });

    const callArgs = mockUseQueryWrapper.mock.calls[0];
    expect(callArgs[0]).toEqual(['embed-origins', 'workspace']);
  });

  it('passes staleTime of 5000ms to coalesce mount/focus/key-change refetches', () => {
    renderHook(() => {
      const { useGetEmbedOrigins } = useEmbedOriginQueries();
      useGetEmbedOrigins('workspace');
    });

    expect(mockUseQueryWrapper).toHaveBeenCalledWith(
      ['embed-origins', 'workspace'],
      expect.any(Function),
      expect.objectContaining({
        staleTime: 5000,
      }),
    );
  });

  it('passes refetchOnMount and refetchOnWindowFocus alongside staleTime', () => {
    renderHook(() => {
      const { useGetEmbedOrigins } = useEmbedOriginQueries();
      useGetEmbedOrigins('organization');
    });

    const callArgs = mockUseQueryWrapper.mock.calls[0];
    expect(callArgs[2]).toEqual(
      expect.objectContaining({
        refetchOnMount: true,
        refetchOnWindowFocus: true,
        staleTime: 5000,
      }),
    );
  });

  it('invokes getEmbedOrigins with the provided scope when the queryFn runs', () => {
    renderHook(() => {
      const { useGetEmbedOrigins } = useEmbedOriginQueries();
      useGetEmbedOrigins('organization');
    });

    const callArgs = mockUseQueryWrapper.mock.calls[0];
    const queryFn = callArgs[1];
    queryFn();
    expect(getEmbedOrigins).toHaveBeenCalledWith('organization');
  });

  it('differentiates the cache key by scope', () => {
    renderHook(() => {
      const { useGetEmbedOrigins } = useEmbedOriginQueries();
      useGetEmbedOrigins('workspace');
      useGetEmbedOrigins('organization');
    });

    expect(mockUseQueryWrapper.mock.calls[0][0]).toEqual(['embed-origins', 'workspace']);
    expect(mockUseQueryWrapper.mock.calls[1][0]).toEqual(['embed-origins', 'organization']);
  });
});
