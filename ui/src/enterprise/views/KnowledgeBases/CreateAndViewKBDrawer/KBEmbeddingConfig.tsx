import { Box } from '@chakra-ui/react';

import InputField from '@/components/InputField';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { getEmbeddingConfiguration } from '@/enterprise/services/embeddingConfiguration';
import EmbeddingConfigurationFields from '@/enterprise/views/Activate/EmbeddingConfiguration/EmbeddingConfigurationFields';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';
import { EmbeddingConfig } from '@/views/Models/types';
import { useEffect, useState } from 'react';

type KBEmbeddingConfigProps = {
  createPayload: CreateKnowledgeBasePayload;
  setCreatePayload: (payload: CreateKnowledgeBasePayload) => void;
  disabled?: boolean;
};

const KBEmbeddingConfig = ({
  disabled = false,
  createPayload,
  setCreatePayload,
}: KBEmbeddingConfigProps) => {
  const { data } = useQueryWrapper(['embedding_providers'], () => getEmbeddingConfiguration());
  const [embeddingConfig, setEmbeddingConfig] = useState<EmbeddingConfig | undefined>({
    api_key: createPayload.embedding_config.api_key,
    model: createPayload.embedding_config.embedding_model,
    mode: createPayload.embedding_config.embedding_provider,
  });

  const embeddingConfigs = data?.data ?? [];

  useEffect(() => {
    setCreatePayload({
      ...createPayload,
      embedding_config: {
        ...createPayload.embedding_config,
        api_key: embeddingConfig?.api_key ?? '',
        embedding_model: embeddingConfig?.model ?? '',
        embedding_provider: embeddingConfig?.mode ?? '',
      },
    });
  }, [embeddingConfig, setCreatePayload]);

  return (
    <Box display='flex' flexDirection='column' gap='24px'>
      <EmbeddingConfigurationFields
        configurations={embeddingConfigs}
        embeddingConfig={embeddingConfig}
        setEmbeddingConfig={setEmbeddingConfig}
        disabled={disabled}
        showAsList
        embeddingApiKeyTestId='create-kb-api-key-input'
      />
      <InputField
        label='Chunk Size'
        name='chunkSize'
        value={createPayload.embedding_config.chunk_size.toString()}
        onChange={(e) =>
          setCreatePayload({
            ...createPayload,
            embedding_config: {
              ...createPayload.embedding_config,
              chunk_size: Number(e.target.value),
            },
          })
        }
        placeholder='1000'
        disabled={disabled}
        isRequired
      />
      <InputField
        label='Chunk Overlap'
        name='overlap'
        value={createPayload.embedding_config.chunk_overlap.toString()}
        onChange={(e) =>
          setCreatePayload({
            ...createPayload,
            embedding_config: {
              ...createPayload.embedding_config,
              chunk_overlap: Number(e.target.value),
            },
          })
        }
        placeholder='250'
        disabled={disabled}
        isRequired
      />
    </Box>
  );
};

export default KBEmbeddingConfig;
