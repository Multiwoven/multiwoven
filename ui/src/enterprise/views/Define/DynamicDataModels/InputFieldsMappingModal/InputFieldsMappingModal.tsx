import BaseModal from '@/components/BaseModal';
import { Box, Button } from '@chakra-ui/react';
import IconEntity from '@/components/IconEntity';
import { BsBracesAsterisk } from 'react-icons/bs';
import SelectField from '@/components/SelectField';
import InputField from '@/components/InputField';
import { useDynamicQueryStore } from '@/enterprise/store/useDynamicQueryStore.ts';
import { SchemaFieldOptions } from '@/enterprise/views/AIMLSources/types/types.ts';
import DocumentationLink from '@/components/DocumentationLink';

const borderProperties = {
  borderStyle: 'solid',
  borderWidth: '1px',
  borderColor: 'gray.400',
};

const InputFieldsMappingModal = ({
  modalOpen,
  setModalOpen,
  handlePreviewClick,
}: {
  modalOpen: boolean;
  setModalOpen: (args: boolean) => void;
  handlePreviewClick: () => void;
}) => {
  const handleModalClose = () => setModalOpen(false);
  const { inputSchema, setInputSchema } = useDynamicQueryStore((state) => state);

  const handleSchemaFieldChange = (index: number, field: Partial<SchemaFieldOptions>) => {
    const updatedFields = inputSchema?.map((fieldMap, mapIndex) =>
      mapIndex === index ? { ...fieldMap, ...field } : fieldMap,
    );
    setInputSchema(updatedFields);
  };

  const isPreviewEnabled = () => {
    if (!inputSchema?.length) return false;
    let canPreview = true;
    for (const schema of inputSchema) {
      if (!schema.type || !schema.sample_input_value) {
        canPreview = false;
        break;
      }
    }
    return canPreview;
  };

  return (
    <BaseModal
      footer={
        <>
          <DocumentationLink label='Read Documentation' />
          <Box display='flex' gap='12px'>
            <Button
              variant='shell'
              minWidth={0}
              width='auto'
              borderColor='gray.400'
              fontSize='12px'
              paddingX='12px'
              backgroundColor='gray.300'
              onClick={handleModalClose}
            >
              Cancel
            </Button>
            <Button
              variant='solid'
              minWidth={0}
              width='auto'
              fontSize='12px'
              paddingX='12px'
              onClick={handlePreviewClick}
              isDisabled={!isPreviewEnabled()}
              data-testid='input-mapping-preview-results'
            >
              Preview Results
            </Button>
          </Box>
        </>
      }
      openModal={modalOpen}
      setModalOpen={handleModalClose}
      title='Add sample inputs'
      description='Add values to your variables to preview results'
      footerAlignment='space-between'
    >
      <Box
        data-testid='input-fields-mapping-modal'
        display='flex'
        flexDirection='column'
        gap='20px'
        height='450px'
        overflow='auto'
      >
        {inputSchema?.map((schema, index) => (
          <Box key={index}>
            <Box
              padding='12px 16px'
              display='flex'
              justifyContent='space-between'
              backgroundColor='gray.300'
              borderTopRadius='8px'
              {...borderProperties}
            >
              <IconEntity icon={BsBracesAsterisk} description={schema.name} />
            </Box>
            <Box
              padding='20px'
              backgroundColor='gray.100'
              borderTopRadius='0'
              borderBottomRadius='8px'
              {...borderProperties}
              borderTopWidth='0'
              display='flex'
              flexDirection='column'
              gap='24px'
            >
              <SelectField
                label='Variable Type'
                placeholder='Select type'
                options={[
                  { value: 'string', label: 'String' },
                  { value: 'number', label: 'Number' },
                  { value: 'boolean', label: 'Boolean' },
                ]}
                onChange={({ target: { value } }) =>
                  handleSchemaFieldChange(index, { type: value })
                }
                value={schema.type}
              />
              <InputField
                label='Variable Value'
                name='variable_value'
                value={schema.sample_input_value as string}
                onChange={({ target: { value } }) => {
                  handleSchemaFieldChange(index, { sample_input_value: value });
                }}
                placeholder='Enter a default value'
              />
            </Box>
          </Box>
        ))}
      </Box>
    </BaseModal>
  );
};

export default InputFieldsMappingModal;
