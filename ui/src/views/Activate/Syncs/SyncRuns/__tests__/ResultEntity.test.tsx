import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { ResultEntity } from '../ResultEntity';

const renderComponent = (props: {
  total_value: number;
  current_value: number;
  result_text: string;
  current_text_color: string;
}) => {
  return render(
    <ChakraProvider>
      <ResultEntity {...props} />
    </ChakraProvider>,
  );
};

describe('ResultEntity', () => {
  it('renders current and total values', () => {
    renderComponent({
      total_value: 100,
      current_value: 75,
      result_text: 'Records',
      current_text_color: 'green',
    });
    expect(screen.getByText('75')).toBeInTheDocument();
    expect(screen.getByText('/100')).toBeInTheDocument();
  });

  it('renders result text', () => {
    renderComponent({
      total_value: 100,
      current_value: 75,
      result_text: 'Records',
      current_text_color: 'green',
    });
    expect(screen.getByText('Records')).toBeInTheDocument();
  });

  it('handles zero values', () => {
    renderComponent({
      total_value: 0,
      current_value: 0,
      result_text: 'No records',
      current_text_color: 'gray',
    });
    expect(screen.getByText('0')).toBeInTheDocument();
    expect(screen.getByText('/0')).toBeInTheDocument();
    expect(screen.getByText('No records')).toBeInTheDocument();
  });

  it('handles different color values', () => {
    renderComponent({
      total_value: 50,
      current_value: 25,
      result_text: 'Items',
      current_text_color: 'red',
    });
    expect(screen.getByText('25')).toBeInTheDocument();
    expect(screen.getByText('Items')).toBeInTheDocument();
  });

  it('displays correct ratio', () => {
    renderComponent({
      total_value: 200,
      current_value: 150,
      result_text: 'Processed',
      current_text_color: 'blue',
    });
    expect(screen.getByText('150')).toBeInTheDocument();
    expect(screen.getByText('/200')).toBeInTheDocument();
    expect(screen.getByText('Processed')).toBeInTheDocument();
  });
});
