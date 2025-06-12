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
import { SyncsConfigurationForTemplateMapping } from '@/views/Activate/Syncs/types';
import { useState } from 'react';
import NoConnectorsFound from '@/assets/images/empty-state-illustration.svg';
import { OPTION_TYPE } from './TemplateOptions';

type ColumnsProps = {
  columnOptions: string[];
  fieldType: 'model' | 'destination';
  catalogMapping?: SyncsConfigurationForTemplateMapping;
  showFilter?: boolean;
  showDescription?: boolean;
  onSelect?: (args: string) => void;
  height?: string;
  templateColumnType?: OPTION_TYPE;
  // New prop for displaying static value
  staticValue?: string | boolean;
};

const Columns = ({
  columnOptions,
  catalogMapping,
  onSelect,
  fieldType,
  templateColumnType,
  showFilter = false,
  showDescription = false,
  height = fieldType === 'model' ? '170px' : '225px',
  staticValue,
}: ColumnsProps): JSX.Element => {
  const [searchTerm, setSearchTerm] = useState<string>('');

  // Enhanced columns - start with the original column options
  let enhancedColumns = [...columnOptions];
  
  // Get stored static value (only for use on destination side)
  let storedStaticValue;
  try {
    storedStaticValue = localStorage.getItem('current_static_value');
  } catch (e) {
    // Silent error handling
  }
  
  // For the destination (HubSpot) dropdown only
  if (fieldType === 'destination') {
    // First try the direct prop - highest priority
    if (staticValue !== undefined && staticValue !== '' && staticValue !== null) {
      const valueAsString = typeof staticValue === 'string' ? staticValue : String(staticValue);
      if (!enhancedColumns.includes(valueAsString)) {
        enhancedColumns.push(valueAsString);
      }
    } 
    // Then try localStorage as a fallback for destination side only
    else if (storedStaticValue && storedStaticValue !== 'null' && storedStaticValue !== 'undefined') {
      if (!enhancedColumns.includes(storedStaticValue)) {
        enhancedColumns.push(storedStaticValue);
      }
    }
  }
  
  // Filtered column options based on search term
  const filteredColumns = enhancedColumns.filter((column) =>
    column.toLowerCase().includes(searchTerm.toLowerCase()),
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
            onClick={() => onSelect?.(column)}
          >
            <Text size='sm'>{column}</Text>
            {showDescription && (
              <Text size='xs' color='gray.600' fontWeight={400}>
                {
                  catalogMapping?.data?.configurations?.catalog_mapping_types?.template?.[
                    templateColumnType === OPTION_TYPE.FILTER ? 'filter' : 'variable'
                  ]?.[column].description
                }
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
