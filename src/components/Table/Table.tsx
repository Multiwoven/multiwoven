import { Box, Table, Tbody, Td, Text, Th, Thead, Tr } from "@chakra-ui/react";
import { TableType } from "./types";

const GenerateTable = ({
  title,
  data,
  size,
  maxHeight,
  onRowClick,
}: TableType): JSX.Element => {
  return (
    <Box
      maxHeight={maxHeight}
      overflowX="scroll"
      borderWidth="thin"
      borderRadius="8px"
      borderColor="gray.300"
    >
      {title ? title : null}
      <Table size={size} maxHeight={maxHeight}>
        <Thead>
          <Tr>
            {data.columns.map((column, index) => (
              <Th key={index} backgroundColor="gray.100">
                <Text fontWeight={700} casing="uppercase">
                  {column.name}
                </Text>
              </Th>
            ))}
          </Tr>
        </Thead>
        <Tbody>
          {data.data.map((row, rowIndex) => (
            <Tr
              key={rowIndex}
              _hover={{ backgroundColor: "gray.50" }}
              onClick={() => onRowClick?.(row)}
            >
              {data.columns.map((column, columnIndex) => (
                <Td key={columnIndex}>{row[column.key as keyof typeof row]}</Td>
              ))}
            </Tr>
          ))}
        </Tbody>
      </Table>
    </Box>
  );
};

export default GenerateTable;
