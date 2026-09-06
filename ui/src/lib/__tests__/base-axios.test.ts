import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import { InternalAxiosRequestConfig } from 'axios';

// Store interceptor handlers
type RequestHandler = (config: InternalAxiosRequestConfig) => InternalAxiosRequestConfig;
type ResponseSuccessHandler = (response: unknown) => unknown;
type ResponseErrorHandler = (error: unknown) => unknown;

// These will be populated when the mocked axios.create is called
let capturedRequestHandler: RequestHandler | null = null;
let capturedResponseSuccessHandler: ResponseSuccessHandler | null = null;
let capturedResponseErrorHandler: ResponseErrorHandler | null = null;

// Create a mock headers object that mimics AxiosHeaders behavior
const createMockHeaders = () => {
  const headers: Record<string, string | undefined> = {};
  return {
    set(key: string, value: string) {
      headers[key] = value;
    },
    get(key: string) {
      return headers[key];
    },
    // Allow direct property access/set like real AxiosHeaders
    ...headers,
  };
};

// Mock axios - factory function doesn't reference external variables
jest.mock('axios', () => {
  class CanceledError extends Error {
    constructor(message?: string) {
      super(message);
      this.name = 'CanceledError';
    }
  }
  const mockInterceptors = {
    request: {
      use: jest.fn(),
    },
    response: {
      use: jest.fn(),
    },
  };

  const mockCreateFn = jest.fn(() => ({
    interceptors: mockInterceptors,
  }));

  return {
    __esModule: true,
    default: {
      create: mockCreateFn,
      CanceledError,
    },
    create: mockCreateFn,
    CanceledError,
  };
});

// Mock cookie functions
const mockGetCookie = jest.fn();
const mockDeleteCookie = jest.fn();
jest.mock('../cookie', () => ({
  getCookie: (name: string) => mockGetCookie(name),
  deleteCookie: (name: string) => mockDeleteCookie(name),
}));

// Mock stores
const mockWorkspaceId = 'workspace-123';
const mockClearState = jest.fn();
const mockClearRoleData = jest.fn();
let mockAppContext = 'default';

jest.mock('@/stores', () => ({
  useStore: {
    getState: () => ({
      workspaceId: mockWorkspaceId,
      clearState: mockClearState,
    }),
  },
}));

jest.mock('@/enterprise/store/useConfigStore', () => ({
  useConfigStore: {
    getState: () => ({
      configs: {
        get appContext() {
          return mockAppContext;
        },
      },
    }),
  },
}));

jest.mock('@/enterprise/store/useRoleDataStore', () => ({
  useRoleDataStore: {
    getState: () => ({
      clearRoleData: mockClearRoleData,
    }),
  },
}));

// Import after mocks are set up
import createBaseAxiosInstance from '../base-axios';
import axios from 'axios';

describe('base-axios', () => {
  const originalLocation = window.location;

  beforeEach(() => {
    jest.clearAllMocks();
    mockAppContext = 'default';
    capturedRequestHandler = null;
    capturedResponseSuccessHandler = null;
    capturedResponseErrorHandler = null;

    // Create instance to capture interceptors
    const instance = createBaseAxiosInstance('https://api.example.com');

    // Capture the interceptors from the mock
    const requestUseMock = instance.interceptors.request.use as jest.Mock;
    const responseUseMock = instance.interceptors.response.use as jest.Mock;

    if (requestUseMock.mock.calls.length > 0) {
      capturedRequestHandler = requestUseMock.mock.calls[0][0];
    }
    if (responseUseMock.mock.calls.length > 0) {
      capturedResponseSuccessHandler = responseUseMock.mock.calls[0][0];
      capturedResponseErrorHandler = responseUseMock.mock.calls[0][1];
    }

    // Mock window.location
    Object.defineProperty(window, 'location', {
      value: {
        ...originalLocation,
        pathname: '/dashboard',
        href: '',
      },
      writable: true,
      configurable: true,
    });
  });

  afterEach(() => {
    Object.defineProperty(window, 'location', {
      value: originalLocation,
      writable: true,
      configurable: true,
    });
  });

  describe('createBaseAxiosInstance', () => {
    it('should create axios instance with correct baseURL', () => {
      createBaseAxiosInstance('https://api.test.com');

      expect(axios.create).toHaveBeenCalledWith({
        baseURL: 'https://api.test.com',
      });
    });

    it('should return axios instance', () => {
      const instance = createBaseAxiosInstance('https://api.test.com');
      expect(instance).toBeDefined();
      expect(instance.interceptors).toBeDefined();
    });

    it('should handle empty baseURL', () => {
      createBaseAxiosInstance('');

      expect(axios.create).toHaveBeenCalledWith({
        baseURL: '',
      });
    });

    it('should handle baseURL with trailing slash', () => {
      createBaseAxiosInstance('https://api.test.com/');

      expect(axios.create).toHaveBeenCalledWith({
        baseURL: 'https://api.test.com/',
      });
    });
  });

  describe('Request Interceptor', () => {
    it('should set Authorization header with auth token', () => {
      mockGetCookie.mockReturnValue('test-token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(mockGetCookie).toHaveBeenCalledWith('authToken');
      expect(result.headers['Authorization']).toBe('Bearer test-token');
    });

    it('should set Workspace-Id header', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Workspace-Id']).toBe('workspace-123');
    });

    it('should set Accept header', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Accept']).toBe('*/*');
    });

    it('should set Data-App headers when appToken is present', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {
          appId: 'app-123',
          appToken: 'app-token-456',
        },
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Data-App-Id']).toBe('app-123');
      expect(result.headers['Data-App-Token']).toBe('app-token-456');
    });

    it('should not set Data-App headers when appToken is not present', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {
          someOtherData: 'value',
        },
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Data-App-Id']).toBeUndefined();
      expect(result.headers['Data-App-Token']).toBeUndefined();
    });

    it('should not set Data-App headers when data is undefined', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Data-App-Id']).toBeUndefined();
      expect(result.headers['Data-App-Token']).toBeUndefined();
    });

    it('should not set Data-App headers when data is null', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: null,
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result.headers['Data-App-Id']).toBeUndefined();
      expect(result.headers['Data-App-Token']).toBeUndefined();
    });

    it('should handle embed context by setting X-App-Context header and embed token', () => {
      mockAppContext = 'embed';
      mockGetCookie.mockImplementation((name: string) => {
        if (name === 'authToken') return 'regular-token';
        if (name === 'embedAuthToken') return 'embed-token';
        return null;
      });

      // Re-create instance to pick up new appContext
      const instance = createBaseAxiosInstance('https://api.test.com');
      const requestUseMock = instance.interceptors.request.use as jest.Mock;
      const lastCallIndex = requestUseMock.mock.calls.length - 1;
      const newHandler = requestUseMock.mock.calls[lastCallIndex][0];

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
      } as unknown as InternalAxiosRequestConfig;

      const result = newHandler(config);

      expect(result.headers['X-App-Context']).toBe('embed');
      expect(result.headers['Authorization']).toBe('Bearer embed-token');
      expect(mockGetCookie).toHaveBeenCalledWith('embedAuthToken');
    });

    it('should return the config object', () => {
      mockGetCookie.mockReturnValue('token');

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
      } as unknown as InternalAxiosRequestConfig;

      const result = capturedRequestHandler!(config);

      expect(result).toBeDefined();
      expect(result.headers).toBeDefined();
    });
  });

  describe('Response Interceptor - Success', () => {
    it('should return config on success', () => {
      const response = { data: { success: true } };
      const result = capturedResponseSuccessHandler!(response);

      expect(result).toEqual(response);
    });

    it('should pass through any successful response', () => {
      const responses = [
        { status: 200, data: 'ok' },
        { status: 201, data: { created: true } },
        { status: 204, data: null },
      ];

      responses.forEach((response) => {
        expect(capturedResponseSuccessHandler!(response)).toEqual(response);
      });
    });
  });

  describe('Response Interceptor - Error Handling', () => {
    it('should handle 401 error and redirect to sign-in', () => {
      const error = {
        response: {
          status: 401,
          data: 'Unauthorized',
        },
      };

      capturedResponseErrorHandler!(error);

      expect(window.location.href).toBe('/sign-in');
      expect(mockDeleteCookie).toHaveBeenCalledWith('authToken');
      expect(mockClearState).toHaveBeenCalled();
      expect(mockClearRoleData).toHaveBeenCalled();
    });

    it('should not redirect on 401 if already on sign-in page', () => {
      window.location.pathname = '/sign-in';

      const error = {
        response: {
          status: 401,
          data: 'Unauthorized',
        },
      };

      capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(mockDeleteCookie).not.toHaveBeenCalled();
      expect(mockClearState).not.toHaveBeenCalled();
    });

    it('should not redirect on 401 if on sso-sign-in page', () => {
      window.location.pathname = '/sso-sign-in';

      const error = {
        response: {
          status: 401,
          data: 'Unauthorized',
        },
      };

      capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(mockDeleteCookie).not.toHaveBeenCalled();
    });

    it('should not redirect on 401 if on data-app render page', () => {
      window.location.pathname = '/render/data-app/123';

      const error = {
        response: {
          status: 401,
          data: 'Unauthorized',
        },
      };

      capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(mockDeleteCookie).not.toHaveBeenCalled();
    });

    it('should handle 403 error without redirect', () => {
      const error = {
        response: {
          status: 403,
          data: 'Forbidden',
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(result).toEqual(error.response);
    });

    it('should handle 501 error without redirect', () => {
      const error = {
        response: {
          status: 501,
          data: 'Not Implemented',
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(result).toEqual(error.response);
    });

    it('should handle 500 error without redirect', () => {
      const error = {
        response: {
          status: 500,
          data: 'Internal Server Error',
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(result).toEqual(error.response);
    });

    it('should handle other error status codes via default case', () => {
      const error = {
        response: {
          status: 404,
          data: 'Not Found',
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(window.location.href).not.toBe('/sign-in');
      expect(result).toEqual(error.response);
    });

    it('should return error.response on error', () => {
      const error = {
        response: {
          status: 400,
          data: { message: 'Bad Request' },
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(result).toEqual(error.response);
    });

    it('should handle error without response object', () => {
      const error = {
        message: 'Network Error',
      };

      const result = capturedResponseErrorHandler!(error);

      expect(result).toBeUndefined();
    });

    it('should handle error with response but no status', () => {
      const error = {
        response: {
          data: 'Some error',
        },
      };

      const result = capturedResponseErrorHandler!(error);

      expect(result).toEqual(error.response);
    });
  });

  describe('Redirect on 401 - Request Cancellation', () => {
    it('should reject subsequent requests with CanceledError after a 401', async () => {
      // Trigger 401 to set loginRedirecting = true
      capturedResponseErrorHandler!({ response: { status: 401 } });

      const headers = createMockHeaders();
      const config = {
        headers,
        data: {},
        url: '/api/test',
      } as unknown as InternalAxiosRequestConfig;

      // Next outgoing request must be cancelled
      await expect(Promise.resolve(capturedRequestHandler!(config))).rejects.toBeInstanceOf(
        axios.CanceledError,
      );
    });

    it('should only redirect once when multiple 401s arrive concurrently', () => {
      const error = { response: { status: 401 } };

      capturedResponseErrorHandler!(error); // first 401 — triggers redirect
      expect(window.location.href).toBe('/sign-in');
      expect(mockDeleteCookie).toHaveBeenCalledTimes(1);

      window.location.href = '';

      capturedResponseErrorHandler!(error);
      expect(window.location.href).toBe('');
      expect(mockDeleteCookie).toHaveBeenCalledTimes(1);
      expect(mockClearState).toHaveBeenCalledTimes(1);
      expect(mockClearRoleData).toHaveBeenCalledTimes(1);
    });
  });
});
