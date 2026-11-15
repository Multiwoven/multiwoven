import { Dispatch, SetStateAction, useEffect, useState } from 'react';

import { Box, Divider, HStack, Image, Text } from '@chakra-ui/react';
import { CustomSelect } from '@/components/CustomSelect/CustomSelect';
import { Option } from '@/components/CustomSelect/Option';

import { useQuery } from '@tanstack/react-query';
import { getAICatalog } from '@/services/syncs';
import { GetAllModelsResponse } from '@/services/models.ts';

import {
  BAR_CHART_PROPERTIES,
  CUSTOM_VISUAL_PROPERTIES,
  DONUT_CHART_PROPERTIES,
  SCATTER_CHART_PROPERTIES,
  TABLE_PROPERTIES,
  CHATBOT_PROPERTIES,
  TEXT_PROPERTIES,
  VisualTypesProps,
} from '@/enterprise/dataApps/visualTypes.ts';
import VisualTypesCarousel from './VisualTypesCarousel';
import VisualComponentConfigRenderer from '@/enterprise/dataApps/components/VisualComponentConfigRenderer';

import FiAICard from '@/assets/icons/FiAICard.svg';
import FiArray from '@/assets/icons/FiArray.svg';
import FiBoolean from '@/assets/icons/FiBoolean.svg';
import FiString from '@/assets/icons/FiString.svg';
import FiInteger from '@/assets/icons/FiInteger.svg';

type AppConfigurationProps = {
  selectedVisualComponent: string | null;
  fieldGroup: string | null | undefined;
  measureValue: string | null | undefined;
  colorByField: string | null | undefined;
  selectedModelId: string | null | undefined;
  fileId: string | null | undefined;
  fileName: string | null | undefined;
  sessionStorageKey: string | null | undefined;
  showVisual?: boolean;
  setFieldGroup: Dispatch<SetStateAction<string | null | undefined>>;
  setFileId: Dispatch<SetStateAction<string | null | undefined>>;
  setFileName: Dispatch<SetStateAction<string | null | undefined>>;
  setMeasureValue: Dispatch<SetStateAction<string | null | undefined>>;
  setColorByField: Dispatch<SetStateAction<string | null | undefined>>;
  setSelectedVisualComponent: Dispatch<SetStateAction<string>>;
  setSelectedModelId: Dispatch<SetStateAction<string | null | undefined>>;
  setSessionStorageKey: Dispatch<SetStateAction<string | null | undefined>>;
  setShowVisual: Dispatch<SetStateAction<boolean | null | undefined>>;
  aiMLModels: GetAllModelsResponse[];
  isEdit?: boolean;
};

const VISUAL_TYPES: VisualTypesProps[] = [
  BAR_CHART_PROPERTIES,
  SCATTER_CHART_PROPERTIES,
  DONUT_CHART_PROPERTIES,
  TABLE_PROPERTIES,
  CHATBOT_PROPERTIES,
  TEXT_PROPERTIES,
  CUSTOM_VISUAL_PROPERTIES,
];

const BadgeIcon = (type: string | undefined) => {
  if (!type) return FiString;
  switch (type.toLowerCase()) {
    case 'string':
      return FiString;
    case 'number':
      return FiInteger;
    case 'array':
      return FiArray;
    case 'boolean':
      return FiBoolean;
    default:
      return FiString;
  }
};

const AppConfiguration = ({
  selectedVisualComponent,
  fieldGroup,
  measureValue,
  colorByField,
  selectedModelId,
  fileId,
  setFileId,
  fileName,
  setFileName,
  sessionStorageKey,
  showVisual,
  setShowVisual,
  setSessionStorageKey,
  setSelectedModelId,
  setFieldGroup,
  setMeasureValue,
  setColorByField,
  setSelectedVisualComponent,
  aiMLModels,
  isEdit = false,
}: AppConfigurationProps) => {
  const [selectedModelConnectorId, setSelectedModelConnectorId] = useState<
    string | null | undefined
  >('');
  const [selectedDynamicModel, setSelectedDynamicModel] = useState<GetAllModelsResponse | null>(
    null,
  );

  const { data: connectorCatalog } = useQuery({
    queryKey: ['ai_catalog', selectedModelConnectorId],
    queryFn: () => getAICatalog(selectedModelConnectorId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    enabled: !!selectedModelConnectorId,
    gcTime: 0,
  });

  const modelFields = selectedDynamicModel
    ? selectedDynamicModel?.attributes?.configuration?.json_schema?.output
    : connectorCatalog?.data?.attributes?.catalog?.streams[0]?.json_schema?.output;

  useEffect(() => {
    if (isEdit && aiMLModels?.length) {
      setSelectedModelId(selectedModelId);
      setSelectedModelConnectorId(
        aiMLModels?.find((model) => model?.id === selectedModelId?.toString())?.attributes
          ?.connector?.id,
      );
    }
  }, [aiMLModels]);

  useEffect(() => {
    const selectedModel = aiMLModels?.find((model) => model?.id === selectedModelId?.toString());
    setSelectedModelConnectorId(selectedModel?.attributes?.connector?.id);
    if (selectedModel?.attributes?.query_type === 'dynamic_sql') {
      setSelectedDynamicModel(selectedModel);
    } else {
      setSelectedDynamicModel(null);
    }
  }, [selectedModelId]);

  return (
    <Box
      flex={1}
      height='100%'
      padding='24px'
      backgroundColor='gray.100'
      borderRadius='8px'
      borderStyle='solid'
      borderWidth='1px'
      borderColor='gray.400'
      overflow={'auto'}
    >
      <Box display='flex' flexDirection='column' gap='12px' marginBottom='12px'>
        <Box display='flex' flexDirection='column' gap='8px'>
          <Text size='sm' fontWeight='semibold'>
            Model
          </Text>
          {aiMLModels?.length && (
            <CustomSelect
              name='ColorMode'
              data-testid='data-app-model-select'
              value={selectedModelId?.toString()}
              onChange={(value) => {
                setSelectedModelId(value);
                const selectedModel = aiMLModels?.find((model) => model?.id === value?.toString());
                setSelectedModelConnectorId(selectedModel?.attributes?.connector?.id);

                // Update selectedDynamicModel only if query_type is dynamic_sql
                if (selectedModel?.attributes?.query_type === 'dynamic_sql') {
                  setSelectedDynamicModel(selectedModel);
                } else {
                  setSelectedDynamicModel(null);
                }
                setFieldGroup(null);
                setMeasureValue(null);
                setColorByField(null);
              }}
              maxH='150px'
              overflowY='scroll'
              placeholder='Select Model'
            >
              {aiMLModels?.map((AIModel) => (
                <Option value={AIModel?.id} key={AIModel?.id}>
                  <HStack>
                    <Image src={FiAICard} h='12px' w='12px' color='black.500' />
                    <Text size='sm' fontWeight={400}>
                      {AIModel?.attributes?.name}
                    </Text>
                  </HStack>
                </Option>
              ))}
            </CustomSelect>
          )}
        </Box>
        <Box
          display='flex'
          flexDirection='column'
          gap='12px'
          backgroundColor='gray.200'
          borderRadius='6px'
          borderStyle='solid'
          borderWidth='1px'
          borderColor='gray.400'
          padding='12px 16px 16px 16px'
        >
          <Text size='xs' letterSpacing='2.4px' color='gray.600' fontWeight={700}>
            MODEL FIELDS
          </Text>
          {!selectedModelId && (
            <Text size='xs' color='gray.600'>
              Select a model first to preview its fields and set up your data app.
            </Text>
          )}
          {selectedModelId && selectedModelId > '' && (
            <Box display='flex' gap='8px' flexWrap='wrap'>
              {modelFields?.map((modelField, index) => (
                <Box
                  padding='2px 8px'
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.500'
                  borderRadius='4px'
                  display='flex'
                  gap='4px'
                  alignItems='center'
                  key={index}
                  minW='fit-content'
                >
                  <Image src={BadgeIcon(modelField?.type)} boxSize='4' color='gray.600' />
                  <Text size='xs' color='black.300' fontWeight='semibold' isTruncated>
                    {modelField?.name}
                  </Text>
                </Box>
              ))}
            </Box>
          )}
        </Box>
      </Box>
      <Box marginY='24px' backgroundColor='gray.400'>
        <Divider orientation='horizontal' />
      </Box>
      <Box marginBottom='24px'>
        <Text size='sm' fontWeight='semibold'>
          Visual Type
        </Text>
        <VisualTypesCarousel
          visualTypes={VISUAL_TYPES}
          selectedVisualType={selectedVisualComponent}
          handleSelectedVisualType={setSelectedVisualComponent}
        />
      </Box>
      {selectedModelId && selectedModelId > '' && (
        <VisualComponentConfigRenderer
          component={selectedVisualComponent}
          modelFields={modelFields ?? []}
          fieldGroup={fieldGroup}
          measureValue={measureValue}
          colorByField={colorByField}
          fileId={fileId}
          fileName={fileName}
          sessionStorageKey={sessionStorageKey}
          showVisual={showVisual}
          setFieldGroup={setFieldGroup}
          setMeasureValue={setMeasureValue}
          setColorByField={setColorByField}
          setFileId={setFileId}
          setFileName={setFileName}
          setSessionStorageKey={setSessionStorageKey}
          setShowVisual={setShowVisual}
        />
      )}
    </Box>
  );
};

export default AppConfiguration;
