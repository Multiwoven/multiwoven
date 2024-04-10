import EntityItem from '@/components/EntityItem';
import { Box, Input } from '@chakra-ui/react';
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

const FieldMap = ({
  id,
  fieldType,
  icon,
  entityName,
  options,
  value,
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
        {fieldType === 'custom' ? (
          <Input
            value={value}
            onChange={(e) => onChange(id, fieldType, e.target.value)}
            isDisabled={isDisabled}
            borderColor={isDisabled ? 'gray.500' : 'gray.400'}
            backgroundColor={isDisabled ? 'gray.300' : 'gray.100'}
          />
        ) : (
          <TemplateMapping
            entityName={entityName}
            isDisabled={isDisabled}
            columnOptions={options ? options : []}
            handleUpdateConfig={onChange}
            mappingId={id}
            selectedConfig={
              fieldType === 'model'
                ? selectedConfigOptions?.[id]?.from
                : selectedConfigOptions?.[id]?.to
            }
            fieldType={fieldType}
          />
        )}
      </Box>
    </Box>
  );
};

export default FieldMap;
