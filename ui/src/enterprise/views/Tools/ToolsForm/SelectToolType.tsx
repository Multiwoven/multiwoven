import { Box, Text, Button, HStack, Grid } from '@chakra-ui/react';
import { useState, useMemo } from 'react';
import ContentContainer from '@/components/ContentContainer';
import useSteppedForm from '@/stores/useSteppedForm';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { getToolDefinitions, getToolDefinition } from '@/enterprise/services/tools';
import { ToolDefinitionTemplate } from '../ToolsList/types';
import { ApiResponse } from '@/services/common';
import Loader from '@/components/Loader';
import ConnectorsGridItem from '@/components/ConnectorsGridItem';
import { Connector } from '@/views/Connectors/types';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';

type TabType = 'all' | 'ai_squared' | 'custom';

const TABS: { value: TabType; label: string }[] = [
  { value: 'all', label: 'All Tools' },
  { value: 'ai_squared', label: 'AI Squared' },
  { value: 'custom', label: 'Custom' },
];

const convertToConnectors = (toolDefinitions: ToolDefinitionTemplate[]): Connector[] => {
  return toolDefinitions.map((tool) => ({
    icon: tool.icon || '',
    name: tool.$id,
    title: tool.title,
    category: tool.category || 'custom',
    connector_spec: {
      connection_specification: tool.properties || {},
    },
  }));
};

const filterConnectors = (connectors: Connector[], activeTab: TabType): Connector[] => {
  if (activeTab === 'custom') {
    return connectors.filter((connector) => connector.category === 'custom');
  }
  if (activeTab === 'ai_squared') {
    return connectors.filter((connector) => connector.category !== 'custom');
  }
  return connectors;
};

const saveToolMetadata = async (
  connector: Connector,
  saveConnectorFormData: any,
  showToast: any,
) => {
  if (!connector?.name) {
    showToast({
      status: CustomToastStatus.Error,
      title: 'Error',
      description: 'Invalid tool selected. Please select a valid tool.',
      position: 'bottom-right',
      isClosable: true,
    });
    return false;
  }

  try {
    const definitionResponse = await getToolDefinition(connector.name);
    const definition = definitionResponse.data;

    const metadata = {
      category: definition?.category ?? 'custom',
      icon: definition?.icon,
      definition_id: connector.name,
    };

    saveConnectorFormData(connector.name, 'metadata', metadata);
    return true;
  } catch (error) {
    const defaultMetadata = {
      category: 'custom',
      definition_id: connector.name,
    };
    saveConnectorFormData(connector.name, 'metadata', defaultMetadata);

    showToast({
      status: CustomToastStatus.Error,
      title: 'Error',
      description: 'Failed to fetch tool definition. Using default values.',
      position: 'bottom-right',
      isClosable: true,
    });
    return true;
  }
};

const SelectToolType = (): JSX.Element => {
  const { handleMoveForward, stepInfo, saveConnectorFormData } = useSteppedForm();
  const [activeTab, setActiveTab] = useState<TabType>('all');
  const showToast = useCustomToast();

  const { data, isLoading } = useQueryWrapper<ApiResponse<ToolDefinitionTemplate[]>>(
    ['tool-definitions'],
    () => getToolDefinitions(),
    {
      refetchOnWindowFocus: false,
      refetchOnMount: true,
    },
  );

  const toolDefinitions = data?.data ?? [];
  const connectors: Connector[] = useMemo(
    () => convertToConnectors(toolDefinitions),
    [toolDefinitions],
  );
  const filteredConnectors = useMemo(
    () => filterConnectors(connectors, activeTab),
    [connectors, activeTab],
  );

  const handleOnClick = async (connector: Connector) => {
    const success = await saveToolMetadata(connector, saveConnectorFormData, showToast);

    if (success && stepInfo?.formKey) {
      handleMoveForward(stepInfo.formKey, connector.name);
    }
  };

  if (isLoading) {
    return <Loader />;
  }

  return (
    <Box display='flex' alignItems='center' justifyContent='center' width='100%'>
      <ContentContainer>
        <HStack spacing='8px' marginBottom='24px'>
          {TABS.map((tab) => (
            <Button
              key={tab.value}
              size='sm'
              borderRadius='100px'
              variant={activeTab === tab.value ? 'solid' : 'outline'}
              colorScheme={activeTab === tab.value ? 'primary' : 'gray'}
              onClick={() => setActiveTab(tab.value)}
            >
              {tab.label}
            </Button>
          ))}
        </HStack>

        {filteredConnectors.length > 0 ? (
          <Grid
            templateColumns='repeat(auto-fit, minmax(min(300px, 100%), 1fr))'
            gap={4}
            width='100%'
          >
            {filteredConnectors.map((connector) => (
              <ConnectorsGridItem
                key={`${connector.name}-${connector.category}`}
                connector={connector}
                onConnectorSelect={handleOnClick}
                hasPermission={true}
                showStatusTag={false}
                testId={`tools-select-definition-${connector.name}`}
              />
            ))}
          </Grid>
        ) : (
          <Box padding='40px' textAlign='center'>
            <Text fontSize='14px' color='gray.500'>
              No tools available yet
            </Text>
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default SelectToolType;
