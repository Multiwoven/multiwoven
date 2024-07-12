import { Stream } from '@/views/Activate/Syncs/types';
import { Box, Text } from '@chakra-ui/react';
import { FiLayout, FiCheck } from 'react-icons/fi';

type ListTableProps = {
  streams?: Stream[];
  selectedTableName: string | null;
  handleTableNameSelection: (tableName: string) => void;
};

const ListTables = ({ streams, selectedTableName, handleTableNameSelection }: ListTableProps) => (
  <Box overflow='auto' height='180px'>
    {streams?.map((stream, index) => (
      <Box
        key={index}
        display='flex'
        padding='8px 12px'
        alignItems='center'
        cursor='pointer'
        _hover={{ backgroundColor: 'gray.300' }}
        backgroundColor={selectedTableName === stream.name ? 'gray.300' : ''}
        borderRadius='4px'
        justifyContent='space-between'
        onClick={() => handleTableNameSelection(stream.name)}
      >
        <Box display='flex' gap='8px' alignItems='center'>
          <Box color='gray.600'>
            <FiLayout />
          </Box>
          <Text>{stream?.name}</Text>
        </Box>
        {selectedTableName === stream.name && (
          <Box color='primary.400'>
            <FiCheck />
          </Box>
        )}
      </Box>
    ))}
  </Box>
);

export default ListTables;
