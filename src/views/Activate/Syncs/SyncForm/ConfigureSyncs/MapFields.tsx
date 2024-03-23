import { ConnectorItem } from '@/views/Connectors/types';
import { ModelEntity } from '@/views/Models/types';
import { Box, Button, CloseButton, Text } from '@chakra-ui/react';
import { getModelPreviewById } from '@/services/models';
import { useQuery } from '@tanstack/react-query';
import { FieldMap as FieldMapType, Stream } from '@/views/Activate/Syncs/types';
import FieldMap from './FieldMap';
import { getPathFromObject, getRequiredProperties } from '@/views/Activate/Syncs/utils';
import { useEffect, useMemo, useState } from 'react';
import { ArrowRightIcon } from '@heroicons/react/24/outline';
import { OPTION_TYPE } from './TemplateMapping/TemplateMapping';

type MapFieldsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  stream: Stream | null;
  data?: FieldMapType[] | null;
  isEdit?: boolean;
  handleOnConfigChange: (args: FieldMapType[]) => void;
  configuration?: FieldMapType[] | null;
};

const MapFields = ({
  model,
  destination,
  stream,
  data,
  isEdit,
  handleOnConfigChange,
  configuration,
}: MapFieldsProps): JSX.Element | null => {
  const [fields, setFields] = useState<FieldMapType[]>([{ from: '', to: '', mapping_type: '' }]);
  const { data: previewModelData } = useQuery({
    queryKey: ['syncs', 'preview-model', model?.connector?.id],
    queryFn: () => getModelPreviewById(model?.query, String(model?.connector?.id)),
    enabled: !!model?.connector?.id,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const destinationColumns = useMemo(() => getPathFromObject(stream?.json_schema), [stream]);
  const requiredDestinationColumns = useMemo(
    () => getRequiredProperties(stream?.json_schema),
    [stream],
  );

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
    type: 'model' | 'destination',
    value: string,
    mappingType = OPTION_TYPE.STANDARD,
  ) => {
    const fieldsClone = [...fields];

    if (type === 'destination') {
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
    if (!isEdit && (configuration || [])?.length === 0) {
      const updatedFields = destinationColumns
        .filter((property) => requiredDestinationColumns.includes(property))
        .map((field) => ({ from: '', to: field, mapping_type: '', isRequired: true }));

      // if only one destination field, we by default select it
      if (destinationColumns.length === 1) {
        updatedFields.push({
          from: '',
          to: destinationColumns[0],
          isRequired: true,
          mapping_type: '',
        });
      }

      if (updatedFields.length > 0) {
        setFields(updatedFields);
        handleOnConfigChange(updatedFields);
      }
    }
  }, [requiredDestinationColumns]);

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
      backgroundColor={isEdit ? 'gray.100' : 'gray.300'}
      padding='24px'
      borderRadius='8px'
      marginBottom={isEdit ? '20px' : '100px'}
    >
      <Text fontWeight={600} size='md'>
        Map fields to {destination?.attributes?.connector_name}
      </Text>
      <Text size='xs' mb={6} letterSpacing='-0.12px' fontWeight={400} color='black.200'>
        Select the API from the Destination that you wish to map.
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
            isDisabled={!stream}
            selectedConfigOptions={configuration}
          />
          <Box width='80px' padding='20px' position='relative' top='8px' color='gray.600'>
            <ArrowRightIcon />
          </Box>
          <FieldMap
            id={index}
            fieldType='destination'
            entityName={destination.attributes.connector_name}
            icon={destination.attributes.icon}
            options={destinationColumns}
            onChange={handleOnChange}
            isDisabled={!stream || isRequired}
            selectedConfigOptions={configuration}
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
          isDisabled={fields.length === modelColumns.length || !stream}
        >
          Add mapping
        </Button>
      </Box>
    </Box>
  );
};

export default MapFields;
