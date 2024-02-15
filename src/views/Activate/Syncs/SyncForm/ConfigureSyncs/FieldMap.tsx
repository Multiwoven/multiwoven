import EntityItem from '@/components/EntityItem';
import { Box, Select } from '@chakra-ui/react';

type FieldMapProps = {
  id: number;
  fieldType: 'model' | 'destination';
  icon: string;
  entityName: string;
  options: string[];
  disabledOptions?: string[];
  value: string;
  isDisabled: boolean;
  onChange: (id: number, type: 'model' | 'destination', value: string) => void;
};

const FieldMap = ({
  id,
  fieldType,
  icon,
  entityName,
  options,
  disabledOptions = [],
  value,
  onChange,
  isDisabled,
}: FieldMapProps): JSX.Element => {
  return (
    <Box width='100%'>
      <Box marginBottom='10px'>
        <EntityItem icon={icon} name={entityName} />
      </Box>
      <Box>
        <Select
          value={value}
          placeholder={`Select a field from ${entityName}`}
          backgroundColor='gray.100'
          isDisabled={isDisabled}
          onChange={(e) => onChange(id, fieldType, e.target.value)}
          isRequired
          borderWidth='1px'
          borderStyle='solid'
          borderColor='gray.400'
          color='gray.600'
        >
          {options.map((option) => (
            <option
              key={option}
              value={option}
              disabled={disabledOptions.includes?.(option)}
            >
              {option}
            </option>
          ))}
        </Select>
      </Box>
    </Box>
  );
};

export default FieldMap;
