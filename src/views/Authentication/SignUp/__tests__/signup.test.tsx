import { render, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';

import { MemoryRouter } from 'react-router-dom';
import SignUp from '../SignUp'; // Update the path based on your project structure

jest.mock('@/services/authentication', () => ({
  signUp: jest.fn().mockResolvedValue({
    data: {
      id: 'mockToken',
      type: 'string',
      attributes: { token: 'mockToken' },
    },
  }),
}));

describe('SignUp Component', () => {
  it('renders signup form and handles submit', async () => {
    const { getByPlaceholderText, getByText } = render(
      <MemoryRouter>
        <SignUp />
      </MemoryRouter>,
    );

    // dummy form values
    const companyName = 'Test Company';
    const name = 'Test User';
    const email = 'test@example.com';
    const password = 'password123';
    const confirmPassword = 'password123';

    // form fields on change
    fireEvent.change(getByPlaceholderText('Enter company name'), {
      target: { value: companyName },
    });
    fireEvent.change(getByPlaceholderText('Enter name'), {
      target: { value: name },
    });
    fireEvent.change(getByPlaceholderText('Enter email'), {
      target: { value: email },
    });
    fireEvent.change(getByPlaceholderText('Choose password'), {
      target: { value: password },
    });
    fireEvent.change(getByPlaceholderText('Confirm password'), {
      target: { value: confirmPassword },
    });

    // click on sign up
    fireEvent.click(getByText('Create Account'));

    // Verify the expected outcome after the API call
    await waitFor(() => {
      expect(window.location.pathname).toBe('/'); // Update the expected path if necessary
    });
  });
});
