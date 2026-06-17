import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import SearchBar from '../SearchBar';

describe('SearchBar', () => {
  it('forwards data-testid to the input', () => {
    const setSearchTerm = jest.fn();
    render(
      <ChakraProvider>
        <SearchBar
          setSearchTerm={setSearchTerm}
          placeholder='Search'
          borderColor='gray.400'
          data-testid='workflow-connector-search'
        />
      </ChakraProvider>,
    );

    const input = screen.getByTestId('workflow-connector-search');
    expect(input).toHaveAttribute('placeholder', 'Search');
    fireEvent.change(input, { target: { value: 'x' } });
    expect(setSearchTerm).toHaveBeenCalled();
  });
});
