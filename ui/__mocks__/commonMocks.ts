/**
 * Common mocks
 * Mock functions for commonly used hooks and utilities across tests
 */

export const mockApiErrorToast = jest.fn();
export const mockErrorToast = jest.fn();

// Hosted store related mocks
export const mockUseGetHostedDBTemplates = jest.fn();
export const mockMutateAsync = jest.fn();

type StoreSelector = (state: Record<string, unknown>) => unknown;

/**
 * Mocks a Zustand store so that the selector function passed by components
 * is actually invoked with the given state, improving coverage.
 */
export function mockStoreImplementation(
  mockedStore: unknown,
  state: Record<string, unknown>,
): void {
  (mockedStore as unknown as jest.Mock).mockImplementation((...args: unknown[]) =>
    (args[0] as StoreSelector)(state),
  );
}
