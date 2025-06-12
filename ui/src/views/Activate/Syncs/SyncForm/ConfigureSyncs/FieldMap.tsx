import EntityItem from '@/components/EntityItem';
import { Box, Input, Button } from '@chakra-ui/react';
import TemplateMapping from './TemplateMapping/TemplateMapping';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import { OPTION_TYPE } from './TemplateMapping/TemplateMapping';
import { FiRefreshCcw } from 'react-icons/fi';

type FieldMapProps = {
  id: number;
  fieldType: 'model' | 'destination' | 'custom';
  icon: string;
  entityName: string;
  handleRefreshCatalog?: () => void;
  options?: string[];
  value?: string;
  disabledOptions?: string[];
  isDisabled: boolean;
  onChange: (id: number, type: 'model' | 'destination' | 'custom', value: string, mappingType?: OPTION_TYPE) => void;
  selectedConfigOptions?: FieldMapType[] | null;
};

const RenderRefreshButton = ({ handleRefreshCatalog }: { handleRefreshCatalog: () => void }) => (
  <Button
    color='black.500'
    borderRadius='6px'
    onClick={handleRefreshCatalog}
    leftIcon={<FiRefreshCcw color='gray.100' />}
    backgroundColor='gray.200'
    variant='shell'
    height='32px'
    minWidth={0}
    width='auto'
    fontSize='12px'
    fontWeight={700}
    lineHeight='18px'
    letterSpacing='-0.12px'
  >
    Refresh
  </Button>
);

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
  handleRefreshCatalog,
}: FieldMapProps): JSX.Element => {
  return (
    <Box width='100%'>
      <Box marginBottom='10px' display='flex' justifyContent='space-between'>
        <EntityItem icon={icon} name={entityName} />
        {fieldType === 'destination' && id === 0 && (
          <RenderRefreshButton handleRefreshCatalog={handleRefreshCatalog as () => void} />
        )}
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
            mappingType={selectedConfigOptions?.[id]?.mapping_type as OPTION_TYPE}
          />
        )}
      </Box>
    </Box>
  );
};

export default FieldMap;
