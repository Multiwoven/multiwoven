import { render, screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const mockGetCookie = jest.fn();

jest.mock('@/lib/cookie', () => ({
  getCookie: (name: string) => mockGetCookie(name),
}));

import PublicOnly from '../public-route';

const renderPublicOnly = (childText = 'sign-in-form') =>
  render(
    <MemoryRouter initialEntries={['/sign-in']}>
      <Routes>
        <Route
          path='/sign-in'
          element={
            <PublicOnly>
              <div>{childText}</div>
            </PublicOnly>
          }
        />
        <Route path='/' element={<div>home-page</div>} />
      </Routes>
    </MemoryRouter>,
  );

describe('PublicOnly', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders children when the loggedIn cookie is missing', () => {
    mockGetCookie.mockReturnValue(undefined);

    renderPublicOnly();

    expect(screen.getByText('sign-in-form')).toBeInTheDocument();
    expect(screen.queryByText('home-page')).not.toBeInTheDocument();
    expect(mockGetCookie).toHaveBeenCalledWith('loggedIn');
  });

  it('renders children when the loggedIn cookie is empty', () => {
    mockGetCookie.mockReturnValue('');

    renderPublicOnly();

    expect(screen.getByText('sign-in-form')).toBeInTheDocument();
  });

  it('redirects to / when the loggedIn cookie is set to "true"', () => {
    mockGetCookie.mockReturnValue('true');

    renderPublicOnly();

    // The auth-page children must NOT render — the router should replace to /.
    expect(screen.queryByText('sign-in-form')).not.toBeInTheDocument();
    expect(screen.getByText('home-page')).toBeInTheDocument();
  });

  it('redirects to / for any truthy value of loggedIn', () => {
    mockGetCookie.mockReturnValue('1');

    renderPublicOnly();

    expect(screen.queryByText('sign-in-form')).not.toBeInTheDocument();
    expect(screen.getByText('home-page')).toBeInTheDocument();
  });

  it('redirects when the loggedIn cookie is the literal string "false"', () => {
    mockGetCookie.mockReturnValue('false');

    renderPublicOnly();

    expect(screen.queryByText('sign-in-form')).not.toBeInTheDocument();
    expect(screen.getByText('home-page')).toBeInTheDocument();
  });

  it('only reads the loggedIn cookie (not authToken)', () => {
    mockGetCookie.mockReturnValue(undefined);

    renderPublicOnly();

    expect(mockGetCookie).toHaveBeenCalledWith('loggedIn');
    expect(mockGetCookie).not.toHaveBeenCalledWith('authToken');
  });
});
