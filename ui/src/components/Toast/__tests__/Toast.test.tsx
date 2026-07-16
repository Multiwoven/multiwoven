import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import Toast, { CustomToastStatus } from '../index';

describe('Toast', () => {
  it('exposes custom toast test ids and status data attribute', () => {
    const onClose = jest.fn();
    render(
      <ChakraProvider>
        <Toast
          title='Saved'
          description='Your changes were saved.'
          status={CustomToastStatus.Success}
          onClose={onClose}
        />
      </ChakraProvider>,
    );

    const root = screen.getByTestId('custom-toast');
    expect(root).toHaveAttribute('data-toast-status', CustomToastStatus.Success);
    expect(screen.getByTestId('custom-toast-title')).toHaveTextContent('Saved');
    expect(screen.getByTestId('custom-toast-description')).toHaveTextContent(
      'Your changes were saved.',
    );

    fireEvent.click(root.querySelector('button') as HTMLButtonElement);
    expect(onClose).toHaveBeenCalled();
  });
});
