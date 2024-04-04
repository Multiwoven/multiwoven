import EntityItem from '@/components/EntityItem';
import { Box, Input, Select } from '@chakra-ui/react';
import TemplateMapping from './TemplateMapping/TemplateMapping';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';

type FieldMapProps = {
  id: number;
  fieldType: 'model' | 'destination' | 'custom';
  icon: string;
  entityName: string;
  options?: string[];
  value?: string;
  disabledOptions?: string[];
  isDisabled: boolean;
  onChange: (id: number, type: 'model' | 'destination' | 'custom', value: string) => void;
  selectedConfigOptions?: FieldMapType[] | null;
};

const DropdownField = ({
  selectedConfigOptions,
  entityName,
  isDisabled,
  id,
  fieldType,
  onChange,
  options,
  disabledOptions,
}: FieldMapProps) => {
  return (
    <Select
      value={selectedConfigOptions?.[id]?.to}
      placeholder={`Select a field from ${entityName}`}
      backgroundColor={isDisabled ? 'gray.300' : 'gray.100'}
      isDisabled={isDisabled}
      onChange={(e) => onChange(id, fieldType, e.target.value)}
      isRequired
      borderWidth='1px'
      borderStyle='solid'
      borderColor={isDisabled ? 'gray.500' : 'gray.400'}
      color='black.500'
      _placeholder={{ color: isDisabled ? 'black.500' : 'gray.600' }}
    >
      {options?.map((option) => (
        <option key={option} value={option} disabled={disabledOptions?.includes?.(option)}>
          {option}
        </option>
      ))}
    </Select>
  );
};

const FieldMap = ({
  id,
  fieldType,
  icon,
  entityName,
  options,
  value,
  disabledOptions = [],
  onChange,
  isDisabled,
  selectedConfigOptions,
}: FieldMapProps): JSX.Element => {
  return (
    <Box width='100%'>
      <Box marginBottom='10px'>
        <EntityItem icon={icon} name={entityName} />
      </Box>
      <Box position='relative'>
        {fieldType === 'destination' ? (
          <DropdownField
            icon={icon}
            selectedConfigOptions={selectedConfigOptions}
            entityName={entityName}
            isDisabled={isDisabled}
            id={id}
            fieldType={fieldType}
            onChange={onChange}
            options={options}
            disabledOptions={disabledOptions}
          />
        ) : fieldType === 'custom' ? (
          <Input value={value} onChange={(e) => onChange(id, fieldType, e.target.value)} />
        ) : (
          <TemplateMapping
            entityName={entityName}
            isDisabled={isDisabled}
            columnOptions={options ? options : []}
            handleUpdateConfig={onChange}
            mappingId={id}
            selectedConfig={selectedConfigOptions?.[id]?.from}
          />
        )}
      </Box>
    </Box>
  );
};

export default FieldMap;
