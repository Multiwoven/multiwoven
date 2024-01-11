import { render, fireEvent, waitFor } from '@testing-library/react';
import { act } from 'react-dom/test-utils';
import { MemoryRouter } from 'react-router-dom';
import SignUp from './SignUp'; // Update the path based on your project structure

jest.mock('../../services/common', () => ({
  signUp: jest.fn().mockResolvedValue({ success: true }),
}));

describe('SignUp Component', () => {
  it('renders signup form and handles submit', async () => {
    const { getByPlaceholderText, getByText } = render(
      <MemoryRouter>
        <SignUp />
      </MemoryRouter>
    );

    // dummy form values
    const companyName = 'Test Company';
    const name = 'Test User';
    const email = 'test@example.com';
    const password = 'password123';
    const confirmPassword = 'password123';

   // form fileds on change
    act(() => {
      fireEvent.change(getByPlaceholderText('Company Name'), { target: { value: companyName } });
      fireEvent.change(getByPlaceholderText('Name'), { target: { value: name } });
      fireEvent.change(getByPlaceholderText('Email'), { target: { value: email } });
      fireEvent.change(getByPlaceholderText('Password'), { target: { value: password } });
      fireEvent.change(getByPlaceholderText('Confirm Password'), { target: { value: confirmPassword } });
    });

    // click on sign up
    act(() => {
      fireEvent.click(getByText('Sign up'));
    });

    // post api call
    await waitFor(() => {
        expect(sessionStorage.getItem('userEmail')).toBe(email);
    });

  });
});
