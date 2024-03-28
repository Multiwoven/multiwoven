import { render, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { expect } from '@jest/globals';
import Cookies from 'js-cookie';
import SignIn from '../SignIn';

jest.mock('@/chakra.config.ts', () => ({
  default: {
    extendThemeWithEnv: jest.fn(),
  },
  'import.meta': {
    env: {
      VITE_LOGO_URL: 'mocked_logo_url',
      VITE_BRAND_COLOR: 'mocked_brand_color',
    },
  },
}));

jest.mock('@/services/common', () => ({
  login: jest.fn().mockResolvedValue({
    success: true,
    response: { data: { token: 'mockToken' } },
  }),
}));

describe('Login Component', () => {
  it('renders login form and handles submit', async () => {
    const { getByText, getByPlaceholderText } = render(
      <MemoryRouter>
        <SignIn />
      </MemoryRouter>,
    );

    // form fileds on change
    const email = 'test@example.com';
    const password = 'password123';

    fireEvent.change(getByPlaceholderText('Enter email'), {
      target: { value: email },
    });
    fireEvent.change(getByPlaceholderText('Enter password'), {
      target: { value: password },
    });

    // click on login
    fireEvent.click(getByText('Sign In'));

    // post api call
    await waitFor(() => {
      if (Cookies) {
        const authTokenCookie = Cookies.get('authToken');
        expect(authTokenCookie).toContain('authToken=mockToken');
        expect(window.location.pathname).toBe('/');
      }
    });
  });
});
