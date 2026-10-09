import { fireEvent, render, screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom';

import { FiTrash2 } from 'react-icons/fi';
import MultiActionButton from '../MultiActionButton';

describe('MultiActionButton', () => {
  const defaultProps = {
    buttonTextColor: 'gray.200',
    buttonHoverColor: 'gray.300',
    textColor: 'black.500',
    icon: FiTrash2,
    iconColor: 'gray.600',
    text: 'Delete Item',
    onClick: jest.fn(),
  };

  it('renders with default props', () => {
    render(<MultiActionButton {...defaultProps} />);

    expect(screen.getByText('Delete Item')).toBeTruthy();
    expect(screen.getByTestId('multi-action-button')).toBeTruthy();
  });

  it('calls onClick handler when clicked', () => {
    render(<MultiActionButton {...defaultProps} />);

    fireEvent.click(screen.getByTestId('multi-action-button'));
    expect(defaultProps.onClick).toHaveBeenCalledTimes(1);
  });
});
