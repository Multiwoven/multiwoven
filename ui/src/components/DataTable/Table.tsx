import { Table, Tbody, Td, Th, Thead, Tr } from '@chakra-ui/react';
import { flexRender, getCoreRowModel, useReactTable, ColumnDef, Row } from '@tanstack/react-table';
import { useState } from 'react';

type DataTableProps<TData, TValue> = {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  onRowClick?: (row: Row<TData>) => void;
<<<<<<< HEAD
};

const DataTable = <TData, TValue>({ data, columns, onRowClick }: DataTableProps<TData, TValue>) => {
=======
  noRowsComponent?: ReactNode;
  getRowProps?: (row: Row<TData>) => DataTableRowProps;
  dataTestId?: string;
  tbodyTestId?: string;
};

const DataTable = <TData, TValue>({
  data,
  columns,
  onRowClick,
  noRowsComponent,
  getRowProps,
  dataTestId,
  tbodyTestId,
}: DataTableProps<TData, TValue>) => {
>>>>>>> e6895d051 (chore(CE): Add data-testid for Knowledge Base E2E Testing (#1891))
  const [rowSelection, setRowSelection] = useState({});

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    onRowSelectionChange: setRowSelection,
    state: {
      rowSelection,
    },
  });

  return (
    <Table data-testid={dataTestId}>
      <Thead bgColor='gray.300'>
        {table.getHeaderGroups().map((headerGroup) => (
          <Tr key={headerGroup.id}>
            {headerGroup.headers.map((header) => (
              <Th
                key={header.id}
                color='black.500'
                fontWeight={700}
                padding='16px'
                letterSpacing='2.4px'
              >
                {header.isPlaceholder
                  ? null
                  : flexRender(header.column.columnDef.header, header.getContext())}
              </Th>
            ))}
          </Tr>
        ))}
      </Thead>
<<<<<<< HEAD
      <Tbody>
        {table.getRowModel().rows.map((row) => (
          <Tr
            key={row.id}
            _hover={{ backgroundColor: 'gray.200', cursor: 'pointer' }}
            onClick={() => onRowClick?.(row)}
            backgroundColor='gray.100'
          >
            {row.getVisibleCells().map((cell) => (
              <Td key={cell.id} padding='16px'>
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </Td>
            ))}
          </Tr>
        ))}
=======
      <Tbody data-testid={tbodyTestId}>
        {table.getRowModel().rows.length > 0
          ? table.getRowModel().rows.map((row) => (
              <Tr
                key={row.id}
                {...(getRowProps?.(row) ?? {})}
                _hover={{ backgroundColor: 'gray.200', cursor: 'pointer' }}
                onClick={() => onRowClick?.(row)}
                backgroundColor='gray.100'
              >
                {row.getVisibleCells().map((cell) => (
                  <Td key={cell.id} padding='16px' maxWidth={'450px'}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </Td>
                ))}
              </Tr>
            ))
          : noRowsComponent && (
              <Tr backgroundColor='gray.100'>
                <Td colSpan={columns.length} padding='16px' textAlign='center'>
                  {noRowsComponent}
                </Td>
              </Tr>
            )}
>>>>>>> e6895d051 (chore(CE): Add data-testid for Knowledge Base E2E Testing (#1891))
      </Tbody>
    </Table>
  );
};

export default DataTable;
