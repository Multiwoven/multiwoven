import SelectField from '@/components/SelectField';
import { Box } from '@chakra-ui/react';
import { Dispatch, SetStateAction, useState } from 'react';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import { EmbeddingConfigurationType } from '@/enterprise/services/types';
import HiddenInput from '@/components/HiddenInput';

type EmbeddingConfigurationFieldsProps = {
  configurations: EmbeddingConfigurationType[];
  embeddingConfig: FieldMapType['embedding_config'];
  setEmbeddingConfig: Dispatch<SetStateAction<FieldMapType['embedding_config']>>;
  showAsList?: boolean;
  apiKeyMt?: string;
  disabled?: boolean;
  embeddingApiKeyTestId?: string;
};

const EmbeddingConfigurationFields = ({
  configurations,
  embeddingConfig,
  setEmbeddingConfig,
  showAsList = false,
  apiKeyMt = '0',
  disabled = false,
  embeddingApiKeyTestId,
}: EmbeddingConfigurationFieldsProps) => {
  const [selectedMode, setSelectedMode] = useState(embeddingConfig?.mode || '');

  const modeOptions = configurations.map((config) => ({
    value: config.attributes.mode,
    label: config.attributes.mode,
  }));

  const getModelOptions = (mode: string) => {
    const config = configurations.find((c) => c.attributes.mode === mode);
    return (
      config?.attributes.models.map((model) => ({
        value: model,
        label: model,
      })) || []
    );
  };

  return (
    <>
      <Box display='flex' gap='24px' flexDirection={showAsList ? 'column' : 'row'}>
        <SelectField
          placeholder='Select Embedding Provider'
          options={modeOptions}
          onChange={({ target: { value } }) => {
            setSelectedMode(value);
            setEmbeddingConfig({ ...embeddingConfig, mode: value });
          }}
          value={selectedMode}
          label='Embedding Provider'
          disabled={disabled}
          isRequired
        />
        <SelectField
          placeholder='Select Embedding Model'
          options={getModelOptions(selectedMode)}
          onChange={({ target: { value } }) =>
            setEmbeddingConfig({ ...embeddingConfig, model: value })
          }
          value={embeddingConfig?.model || ''}
          label='Embedding Model'
          disabled={disabled}
          isRequired
        />
      </Box>
      <Box display='flex' gap='24px' flexDirection={showAsList ? 'column' : 'row'} mt={apiKeyMt}>
        <Box flex={1}>
          <HiddenInput
            type='password'
            label='API Key'
            name='apiKey'
            fontSize='14px'
            value={embeddingConfig?.api_key || ''}
            onChange={({ target: { value } }) =>
              setEmbeddingConfig({ ...embeddingConfig, api_key: value })
            }
            placeholder='Enter your API key'
            isDisabled={disabled}
            isRequired
            data-testid={embeddingApiKeyTestId ?? 'hidden-input-field'}
          />
        </Box>
        {!showAsList && <Box flex={1} />}
      </Box>
    </>
  );
};

export default EmbeddingConfigurationFields;
