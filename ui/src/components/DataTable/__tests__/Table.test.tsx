import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import type { ColumnDef, Row as TanStackRow } from '@tanstack/react-table';
import DataTable from '../Table';

type RowData = { id: string; name: string };

describe('DataTable', () => {
  const columns: ColumnDef<RowData, string>[] = [
    { accessorKey: 'name', header: 'Name', cell: (info) => info.getValue() },
  ];

  const data: RowData[] = [
    { id: 'a', name: 'Alpha' },
    { id: 'b', name: 'Beta' },
  ];

  it('merges getRowProps onto each row', () => {
    render(
      <ChakraProvider>
        <DataTable
          data={data}
          columns={columns}
          getRowProps={(row) => ({
            'data-testid': `row-${row.original.id}`,
            'data-row-label': row.original.name,
          })}
        />
      </ChakraProvider>,
    );

    const first = screen.getByTestId('row-a');
    expect(first).toHaveAttribute('data-row-label', 'Alpha');
    expect(screen.getByTestId('row-b')).toHaveAttribute('data-row-label', 'Beta');
  });

  it('invokes onRowClick with the row when a row is clicked', () => {
    const onRowClick = jest.fn();
    render(
      <ChakraProvider>
        <DataTable
          data={data}
          columns={columns}
          getRowProps={(row) => ({ 'data-testid': `row-${row.original.id}` })}
          onRowClick={onRowClick}
        />
      </ChakraProvider>,
    );

    fireEvent.click(screen.getByTestId('row-a'));
    expect(onRowClick).toHaveBeenCalledTimes(1);
    const clicked = onRowClick.mock.calls[0][0] as TanStackRow<RowData>;
    expect(clicked.original).toEqual(data[0]);
  });
});
