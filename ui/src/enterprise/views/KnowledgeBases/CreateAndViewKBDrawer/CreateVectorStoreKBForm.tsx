import { Box, Input, Text } from '@chakra-ui/react';
import VectorStoreConfig from './VectorStoreConfig';
import KBEmbeddingConfig from './KBEmbeddingConfig';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';

type CreateVectorStoreKBFormProps = {
  createPayload: CreateKnowledgeBasePayload;
  setCreatePayload: (payload: CreateKnowledgeBasePayload) => void;
  readonly?: boolean;
};

const CreateVectorStoreKBForm = ({
  createPayload,
  setCreatePayload,
  readonly = false,
}: CreateVectorStoreKBFormProps) => {
  return (
    <Box display='flex' flexDirection='column' gap='24px' width='100%'>
      <Box display='flex' flexDirection='column' gap='8px' width='100%'>
        <Box display='flex' flexDirection='row' gap='1px' alignItems='center'>
          <Text size='sm' fontWeight='semibold'>
            Name
          </Text>
          <Text size='sm' color='error.400'>
            *
          </Text>
        </Box>
        <Input
          data-testid='create-kb-name-input'
          w='100%'
          placeholder='Enter name'
          value={createPayload.name}
          fontSize='14px'
          onChange={(e) => setCreatePayload({ ...createPayload, name: e.target.value })}
          isReadOnly={readonly}
        />
      </Box>
      <Box
        width='100%'
        borderTop='1px solid'
        borderColor='gray.400'
        height='0px'
        data-testid='divider'
      ></Box>
      <KBEmbeddingConfig
        createPayload={createPayload}
        setCreatePayload={setCreatePayload}
        disabled={readonly}
      />
      <Box
        width='100%'
        borderTop='1px solid'
        borderColor='gray.400'
        height='0px'
        data-testid='divider'
      ></Box>
      <VectorStoreConfig
        createPayload={createPayload}
        setCreatePayload={setCreatePayload}
        readonly={readonly}
      />
    </Box>
  );
};

export default CreateVectorStoreKBForm;
