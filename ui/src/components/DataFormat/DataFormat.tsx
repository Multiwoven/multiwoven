import { Box, Select, Textarea } from '@chakra-ui/react';
import EntityItem from '@/components/EntityItem';
import FiInternal from '@/assets/icons/FiInternal.svg';
import FiExternalLink from '@/assets/icons/FiExternalLink.svg';

type DataFormatProps = {
  type: 'request' | 'response';
  onChange: (value: string) => void;
  value: string;
  required?: boolean;
};

const DataFormat = ({ type, onChange, value, required }: DataFormatProps) => (
  <Box borderWidth='1px' borderStyle='solid' borderColor='gray.400' borderRadius='6px'>
    <Box
      paddingX='20px'
      paddingY='12px'
      backgroundColor='gray.300'
      display='flex'
      justifyContent='space-between'
    >
      <EntityItem
        icon={type === 'request' ? FiExternalLink : FiInternal}
        name={type === 'request' ? 'Request Format' : 'Response Format'}
      />
      <Select
        backgroundColor='gray.100'
        maxWidth='240px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        fontSize='14px'
      >
        <option value='json'>JSON</option>
      </Select>
    </Box>
    <Textarea
      value={value}
      placeholder='1   {"Content-Type":"application/json"}'
      background='gray.100'
      resize='none'
      onChange={(event) => onChange(event.target.value)}
      required={required}
      borderTopRadius={0}
      border='none'
      focusBorderColor='gray.400'
      fontSize='12px'
      colorScheme='black'
      height='190px'
    />
  </Box>
);

export default DataFormat;
