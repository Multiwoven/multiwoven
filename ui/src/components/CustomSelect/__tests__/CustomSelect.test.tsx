import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { CustomSelect } from '../CustomSelect';
import { Option } from '../Option';

describe('CustomSelect', () => {
  it('forwards data-testid to the toggle button', () => {
    render(
      <ChakraProvider>
        <CustomSelect
          value='one'
          data-testid='connector-widget-select'
          onChange={() => {}}
          placeholder='Choose'
        >
          <Option value='one'>One</Option>
          <Option value='two'>Two</Option>
        </CustomSelect>
      </ChakraProvider>,
    );

    expect(screen.getByTestId('connector-widget-select')).toBeInTheDocument();
  });
});
