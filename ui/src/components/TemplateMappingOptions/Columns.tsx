import {
  Box,
  Stack,
  Text,
  Input,
  InputGroup,
  InputLeftElement,
  Icon,
  VStack,
} from '@chakra-ui/react';
import { FiSearch } from 'react-icons/fi';
import { useState } from 'react';
import NoConnectorsFound from '@/assets/images/empty-state-illustration.svg';
import { ColumnsProps } from './types';

const Columns = ({
  columnOptions,
  onSelect,
  fieldType,
  showFilter = false,
  showDescription = false,
  height = fieldType === 'model' ? '170px' : '225px',
}: ColumnsProps): JSX.Element => {
  const [searchTerm, setSearchTerm] = useState<string>('');

  // Filtered column options based on search term
  const filteredColumns = columnOptions.filter((column) =>
    column.name.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <Stack gap='12px' height='100%'>
      {showFilter && (
        <InputGroup>
          <InputLeftElement pointerEvents='none'>
            <Icon as={FiSearch} color='gray.600' boxSize='5' />
          </InputLeftElement>
          <Input
            placeholder='Search Columns'
            _placeholder={{ color: 'gray.600' }}
            borderColor='black.500'
            _hover={{ borderColor: 'black.500' }}
            onChange={({ target: { value } }) => setSearchTerm(value)}
          />
        </InputGroup>
      )}
      <Box height={height} overflowY='auto'>
        {filteredColumns.map((column, index) => (
          <Box
            key={index}
            paddingY='10px'
            paddingX='16px'
            display='flex'
            gap='12px'
            _hover={{
              backgroundColor: 'gray.200',
            }}
            cursor='pointer'
            flexDirection='column'
            onClick={() => onSelect?.(column.value)}
          >
            <Text size='sm'>{column.name}</Text>
            {showDescription && (
              <Text size='xs' color='gray.600' fontWeight={400}>
                {column.description}
              </Text>
            )}
          </Box>
        ))}
        {filteredColumns.length === 0 && (
          <VStack justify='center' height='100%'>
            <img src={NoConnectorsFound} alt='no-connectors-found' />
            <Text color='gray.600' size='xs' fontWeight='semibold'>
              No results found
            </Text>
          </VStack>
        )}
      </Box>
    </Stack>
  );
};

export default Columns;
