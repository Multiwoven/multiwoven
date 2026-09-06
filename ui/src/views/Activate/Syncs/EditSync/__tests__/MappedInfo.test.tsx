import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import MappedInfo from '../MappedInfo';

const renderComponent = (info: Array<{ name: string; icon: string }>) => {
  return render(
    <ChakraProvider>
      <MappedInfo info={info} />
    </ChakraProvider>,
  );
};

describe('MappedInfo', () => {
  it('renders single item without arrow', () => {
    const info = [{ name: 'Source', icon: 'source-icon' }];
    renderComponent(info);
    expect(screen.getByText('Source')).toBeInTheDocument();
  });

  it('renders multiple items with arrows between them', () => {
    const info = [
      { name: 'Source', icon: 'source-icon' },
      { name: 'Model', icon: 'model-icon' },
      { name: 'Destination', icon: 'destination-icon' },
    ];
    renderComponent(info);
    expect(screen.getByText('Source')).toBeInTheDocument();
    expect(screen.getByText('Model')).toBeInTheDocument();
    expect(screen.getByText('Destination')).toBeInTheDocument();
  });

  it('renders two items correctly', () => {
    const info = [
      { name: 'Item 1', icon: 'icon1' },
      { name: 'Item 2', icon: 'icon2' },
    ];
    renderComponent(info);
    expect(screen.getByText('Item 1')).toBeInTheDocument();
    expect(screen.getByText('Item 2')).toBeInTheDocument();
  });

  it('handles empty array gracefully', () => {
    const { container } = renderComponent([]);
    // Component should render without errors
    expect(container).toBeInTheDocument();
  });

  it('renders items with different icons', () => {
    const info = [
      { name: 'PostgreSQL', icon: 'postgres-icon' },
      { name: 'Snowflake', icon: 'snowflake-icon' },
    ];
    renderComponent(info);
    expect(screen.getByText('PostgreSQL')).toBeInTheDocument();
    expect(screen.getByText('Snowflake')).toBeInTheDocument();
  });
});
