import { Table, Tbody, Td, Th, Thead, Tr } from '@chakra-ui/react';
import { flexRender, getCoreRowModel, useReactTable, ColumnDef, Row } from '@tanstack/react-table';
<<<<<<< HEAD
import { useState } from 'react';
=======
import { useState, ReactNode, ComponentProps } from 'react';

type DataTableRowProps = ComponentProps<typeof Tr>;
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))

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
};

const DataTable = <TData, TValue>({
  data,
  columns,
  onRowClick,
  noRowsComponent,
  getRowProps,
}: DataTableProps<TData, TValue>) => {
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))
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
    <Table>
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
      <Tbody>
<<<<<<< HEAD
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
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))
      </Tbody>
    </Table>
  );
};

export default DataTable;
