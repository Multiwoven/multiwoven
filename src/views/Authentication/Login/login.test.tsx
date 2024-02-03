import { render, fireEvent, waitFor } from '@testing-library/react';
import { act } from 'react-dom/test-utils';
import { MemoryRouter } from 'react-router-dom';
import Login from './Login';
import Cookies from 'js-cookie';

jest.mock('@/services/common', () => ({
  login: jest.fn().mockResolvedValue({ success: true, response: { data: { token: 'mockToken' } } }),
}));

describe('Login Component', () => {
  it('renders login form and handles submit', async () => {
    const { getByText, getByPlaceholderText } = render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>
    );

    // dummy form values
    const email = 'test@example.com';
    const password = 'password123';

    // form fileds on change
    act(() => {
      fireEvent.change(getByPlaceholderText('Email'), { target: { value: email } });
      fireEvent.change(getByPlaceholderText('********'), { target: { value: password } });
    });

    // click on login
    act(() => {
      fireEvent.click(getByText('Sign in'));
    });

    // post api call
    await waitFor(() => {
      if (Cookies) {
        const authTokenCookie = Cookies.get('authToken');
        expect(authTokenCookie).toContain('authToken=mockToken')
        expect(window.location.pathname).toBe('/');
      }
    });
  });
});
