import { Box, Table, Tbody, Td, Th, Thead, Tr } from "@chakra-ui/react";
import { TableType } from "./types";

const GenerateTable = ({
  title,
  data,
  size,
  headerColor,
  headerColorVisible,
  borderRadius,
  onRowClick,
}: TableType): JSX.Element => {
  const theadProps = headerColorVisible
    ? { bgColor: headerColor || "gray.200" }
    : {};

  return (
    <Box
      border="1px"
      borderColor="gray.300"
      borderRadius={borderRadius || "lg"}
    >
      {title ? title : <></>}
      <Table size={size}>
        <Thead {...theadProps}>
          <Tr>
            {data.columns.map((column, index) => (
              <Th key={index}>{column}</Th>
            ))}
          </Tr>
        </Thead>
        <Tbody>
          {data.data.map((row, rowIndex) => (
            <Tr
              key={rowIndex}
              _hover={{ backgroundColor: "gray.100" }}
              onClick={() => onRowClick?.(row)}
            >
              {Object.values(row).map((value, valueIndex) => (
                <Td key={valueIndex}>{value}</Td>
              ))}
            </Tr>
          ))}
        </Tbody>
      </Table>
    </Box>
  );
};

export default GenerateTable;
