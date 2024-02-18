import {
  Box,
  Flex,
  Table,
  Tbody,
  Td,
  Text,
  Th,
  Thead,
  Tr,
} from '@chakra-ui/react';
import { TableType } from './types';
import EntityItem from '../EntityItem';

const GenerateTable = ({
  title,
  data,
  size,
  headerColor,
  headerColorVisible,
  borderRadius,
  maxHeight,
  onRowClick,
  minWidth,
}: TableType): JSX.Element => {
  const theadProps = headerColorVisible
    ? { bgColor: headerColor || 'gray.200' }
    : {};
  return (
    <Box
      border='1px'
      borderColor='gray.400'
      borderRadius={borderRadius || 'lg'}
      maxHeight={maxHeight}
      minWidth={minWidth}
      overflowX='scroll'
    >
      {title ? title : <></>}
      <Table size={size} maxHeight={maxHeight}>
        <Thead {...theadProps} bgColor='gray.300'>
          <Tr>
            {data.columns.map((column, index) => (
              <Th
                key={index}
                color='black.500'
                fontWeight={700}
                padding='16px'
                letterSpacing='2.4px'
              >
                {column.name}
              </Th>
            ))}
          </Tr>
        </Thead>
        <Tbody>
          {data.data.map((row, rowIndex) => (
            <Tr
              key={rowIndex}
              _hover={{ backgroundColor: 'gray.200', cursor: 'pointer' }}
              onClick={() => onRowClick?.(row)}
              backgroundColor='gray.100'
            >
              {data.columns.map((column, columnIndex) => (
                <Td key={columnIndex} padding='20px'>
                  {column.showIcon ? (
                    <Flex
                      flexDir='row'
                      alignItems='center'
                      alignContent='center'
                    >
                      <EntityItem
                        name={row[column.key as keyof typeof row] || ''}
                        icon={row.icon || ''}
                      />
                    </Flex>
                  ) : (
                    <Text size='sm' color='gray.700' fontWeight={500}>
                      {row[column.key as keyof typeof row]}
                    </Text>
                  )}
                </Td>
              ))}
            </Tr>
          ))}
        </Tbody>
      </Table>
    </Box>
  );
};

export default GenerateTable;
