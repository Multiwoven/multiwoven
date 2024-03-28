import { ConnectorItem } from '@/views/Connectors/types';
import { ModelEntity } from '@/views/Models/types';
import { Box, Button, CloseButton, Text } from '@chakra-ui/react';
import { getModelPreviewById } from '@/services/models';
import { useQuery } from '@tanstack/react-query';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import FieldMap from './FieldMap';
import { useEffect, useState } from 'react';
import { ArrowRightIcon } from '@heroicons/react/24/outline';
import { OPTION_TYPE } from './TemplateMapping/TemplateMapping';

type MapCustomFieldsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  data?: FieldMapType[] | null;
  isEdit?: boolean;
  handleOnConfigChange: (args: FieldMapType[]) => void;
  configuration?: FieldMapType[] | null;
};

const MapCustomFields = ({
  model,
  destination,
  data,
  isEdit,
  handleOnConfigChange,
  configuration,
}: MapCustomFieldsProps): JSX.Element | null => {
  const [fields, setFields] = useState<FieldMapType[]>([{ from: '', to: '', mapping_type: '' }]);
  const { data: previewModelData } = useQuery({
    queryKey: ['syncs', 'preview-model', model?.connector?.id],
    queryFn: () => getModelPreviewById(model?.query, String(model?.connector?.id)),
    enabled: !!model?.connector?.id,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (data) {
      if (Array.isArray(data)) {
        setFields(data);
      } else {
        const fields = Object.keys(data).map((modelKey) => ({
          from: modelKey,
          to: data[modelKey],
          mapping_type: 'standard',
        }));
        setFields(fields);
      }
    }
  }, [data]);

  const firstRow = Array.isArray(previewModelData) && previewModelData[0];

  const modelColumns = Object.keys(firstRow ?? {});

  const handleOnAppendField = () => {
    setFields([...fields, { from: '', to: '', mapping_type: '' }]);
  };

  const handleOnChange = (
    id: number,
    type: 'model' | 'destination' | 'custom',
    value: string,
    mappingType = OPTION_TYPE.STANDARD,
  ) => {
    const fieldsClone = [...fields];

    if (type === 'destination' || type === 'custom') {
      fieldsClone[id] = {
        ...fieldsClone[id],
        to: value,
      };
    } else {
      fieldsClone[id] = {
        ...fieldsClone[id],
        from: value,
        mapping_type: mappingType,
      };
    }

    setFields(fieldsClone);
    handleOnConfigChange(fieldsClone);
  };

  const handleRemoveMap = (id: number) => {
    const newFields = fields.filter((_, index) => index !== id);
    setFields(newFields);
    handleOnConfigChange(newFields);
  };

  const mappedColumns = fields.map((item) => item.from);

  useEffect(() => {
    let FieldStruct: FieldMapType[] = [];
    if (configuration) {
      if (configuration.length === 0) {
        FieldStruct = [{ from: '', to: '', mapping_type: '' }];
      } else {
        FieldStruct = configuration;
      }
      setFields(FieldStruct);
    }
  }, []);

  return (
    <Box
      backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
      padding='24px'
      borderRadius='8px'
      marginBottom={isEdit ? '20px' : '100px'}
    >
      <Text fontWeight={600} size='md'>
        Map Custom Fields to {destination?.attributes?.connector_name}
      </Text>
      <Text size='xs' mb={6} letterSpacing='-0.12px' fontWeight={400} color='black.200'>
        Configure how the columns in your query results should be mapped to custom fields in{' '}
        {destination?.attributes?.connector_name}.
      </Text>
      {fields.map(({ isRequired = false }, index) => (
        <Box key={`field-map-${index}`} display='flex' alignItems='flex-end' marginBottom='30px'>
          <FieldMap
            id={index}
            fieldType='model'
            entityName={model.connector.connector_name}
            icon={model.connector.icon}
            options={modelColumns}
            disabledOptions={mappedColumns}
            onChange={handleOnChange}
            isDisabled={false}
            selectedConfigOptions={configuration}
          />
          <Box width='80px' padding='20px' position='relative' top='8px' color='gray.600'>
            <ArrowRightIcon />
          </Box>
          <FieldMap
            id={index}
            icon={destination.attributes.icon}
            entityName={destination.attributes.connector_name}
            isDisabled={false}
            value={fields[index].to}
            onChange={handleOnChange}
            fieldType='custom'
          />
          {!isRequired && (
            <Box py='20px' position='relative' top='12px' color='gray.600'>
              <CloseButton
                size='sm'
                marginLeft='10px'
                _hover={{ backgroundColor: 'none' }}
                onClick={() => handleRemoveMap(index)}
              />
            </Box>
          )}
        </Box>
      ))}
      <Box>
        <Button
          variant='shell'
          onClick={handleOnAppendField}
          height='32px'
          minWidth={0}
          width='auto'
          fontSize='12px'
          fontWeight={700}
          lineHeight='18px'
          letterSpacing='-0.12px'
          isDisabled={fields.length === modelColumns.length}
        >
          Add mapping
        </Button>
      </Box>
    </Box>
  );
};

export default MapCustomFields;
