import { Table, Tbody, Td, Th, Thead, Tr } from '@chakra-ui/react';
import { flexRender, getCoreRowModel, useReactTable, ColumnDef } from '@tanstack/react-table';

type DataTableProps<TData, TValue> = {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
};

const DataTable = <TData, TValue>({ data, columns }: DataTableProps<TData, TValue>) => {
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
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
        {table.getRowModel().rows.map((row) => (
          <Tr
            key={row.id}
            _hover={{ backgroundColor: 'gray.200', cursor: 'pointer' }}
            //  onClick={() => onRowClick?.(row)}
            backgroundColor='gray.100'
          >
            {row.getVisibleCells().map((cell) => (
              <Td key={cell.id} padding='16px'>
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </Td>
            ))}
          </Tr>
        ))}
      </Tbody>
    </Table>
  );
};

export default DataTable;
