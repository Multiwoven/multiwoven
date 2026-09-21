import {
  Box,
  Button,
  Flex,
  FormControl,
  FormLabel,
  Switch,
  Text,
  useDisclosure,
} from '@chakra-ui/react';
import { WidgetProps } from '@rjsf/utils';
import { useEffect, useState } from 'react';
import { FiInfo } from 'react-icons/fi';
import { Select } from 'chakra-react-select';
import useToolQueries from '@/enterprise/hooks/queries/useToolQueries';
import { ToolItem } from '@/enterprise/views/Tools/ToolsList/types';
import { ConnectedToolView, AddToolButton, ToolIcon } from './ToolSelector';
import BaseModal from '@/components/BaseModal/BaseModal';
import ToolTip from '@/components/ToolTip/ToolTip';
import Loader from '@/components/Loader';

const MAX_TOOLS_PER_PAGE = 999;

export interface ToolSelectorFormContext {
  currentTools?: string[];
  configuration?: {
    tool_id?: string;
    tools?: string[];
  };
  onToolSelectorChange?: (toolId: string | undefined, tools: string[]) => void;
}

type ToolSelectorWidgetProps = Omit<WidgetProps, 'formContext'> & {
  formContext?: ToolSelectorFormContext;
};

const ToolSelectorWidget = ({ value, formContext }: ToolSelectorWidgetProps) => {
  const { isOpen: isModalOpen, onOpen: onModalOpen, onClose: onModalClose } = useDisclosure();

  const [selectedTool, setSelectedTool] = useState<ToolItem | null>(null);
  const [actionStates, setActionStates] = useState<Record<string, boolean>>({});

  const toolId = typeof value === 'string' ? value : '';
  const tools = formContext?.currentTools ?? [];

  const { useGetTools, useGetMcpToolsList } = useToolQueries();
  const { data: toolsResponse, isLoading: isLoadingTools } = useGetTools(1, MAX_TOOLS_PER_PAGE);
  const allTools: ToolItem[] = toolsResponse?.data ?? [];

  const shouldFetchActions = isModalOpen && !!selectedTool?.id;
  const { data: mcpToolsResponse, isLoading: isLoadingActions } = useGetMcpToolsList(
    selectedTool?.id ?? null,
    shouldFetchActions,
  );

  const toolActions = mcpToolsResponse?.tools ?? [];

  const currentTool = (toolId ? allTools.find((t) => t.id === toolId) : undefined) ?? null;
  const selectedActionsCount = toolActions.filter((a) => actionStates[a.name] === true).length;

  const isActionChecked = (actionName: string): boolean => actionStates[actionName] === true;

  const allSelected = selectedActionsCount === toolActions.length && toolActions.length > 0;
  const someSelected = selectedActionsCount > 0 && selectedActionsCount < toolActions.length;

  const handleSelectAll = () => {
    setActionStates(Object.fromEntries(toolActions.map((a) => [a.name, true])));
  };

  const handleDeselectAll = () => {
    setActionStates({});
  };

  useEffect(() => {
    if (toolActions.length > 0 && Object.keys(actionStates).length === 0) {
      setActionStates(Object.fromEntries(toolActions.map((a) => [a.name, true])));
    }
  }, [mcpToolsResponse]);

  const handleSelectTool = (tool: ToolItem) => {
    setSelectedTool(tool);
    setActionStates({});
  };

  const handleActionToggle = (actionName: string) => {
    setActionStates((prev) => ({
      ...prev,
      [actionName]: !prev[actionName],
    }));
  };

  const handleCloseModal = () => {
    setActionStates({});
    setSelectedTool(null);
    onModalClose();
  };

  const handleConfirm = () => {
    if (!selectedTool) return;
    const selectedActions = toolActions.filter((a) => isActionChecked(a.name)).map((a) => a.name);
    formContext?.onToolSelectorChange?.(selectedTool.id, selectedActions);
    handleCloseModal();
  };

  const handleEditTool = () => {
    if (!currentTool) return;
    setSelectedTool(currentTool);
    const existingStates = Object.fromEntries(tools.map((actionId) => [actionId, true]));
    setActionStates(existingStates);
    onModalOpen();
  };

  const toolOptions = allTools.map((t) => ({
    value: t.id,
    label: t.attributes.name,
    tool: t,
  }));

  const selectedToolOption = selectedTool
    ? toolOptions.find((o) => o.value === selectedTool.id) ?? null
    : null;

  return (
    <Box>
      {toolId ? (
        <ConnectedToolView currentTool={currentTool} tools={tools} onEditTool={handleEditTool} />
      ) : (
        <AddToolButton onClick={onModalOpen} />
      )}

      <BaseModal
        openModal={isModalOpen}
        setModalOpen={(open) => {
          if (!open) handleCloseModal();
        }}
        title={'Add Tool'}
        modalBodyWidth='540px'
        maxHeight='600px'
        bodyPaddingX='24px'
        bodyPaddingY='0px'
        bodyPaddingTop='8px'
        bodyPaddingBottom='8px'
        footer={
          <Flex justifyContent='flex-end' gap='12px' width='100%'>
            <Button
              data-testid='workflow-tool-modal-cancel'
              variant='ghost'
              onClick={handleCloseModal}
              backgroundColor='gray.300'
              border='1px solid'
              borderColor='gray.400'
              fontWeight={700}
              fontSize='14px'
              height='40px'
              padding='0px 16px'
            >
              Cancel
            </Button>
            <Button
              data-testid='workflow-tool-modal-connect'
              colorScheme='brand'
              onClick={handleConfirm}
              isDisabled={!selectedTool || isLoadingActions || selectedActionsCount === 0}
              fontWeight={700}
              fontSize='14px'
              height='40px'
              padding='0px 16px'
            >
              Connect
            </Button>
          </Flex>
        }
        addFooterStroke={true}
        showCloseButton={true}
      >
        <Flex direction='column' gap='16px' paddingTop='8px'>
          {/* Section 1: Connection dropdown */}
          <FormControl>
            <FormLabel fontSize='14px' fontWeight={600} mb='8px'>
              Select Connection
            </FormLabel>
            <Box data-testid='workflow-tool-connection-select'>
              <Select
                isSearchable
                placeholder='Select a tool connection'
                isLoading={isLoadingTools}
                options={toolOptions}
                value={selectedToolOption}
                onChange={(option) => {
                  if (option) handleSelectTool(option.tool);
                }}
                formatOptionLabel={(option) => (
                  <Flex
                    data-testid={`workflow-tool-connection-option-${option.value}`}
                    alignItems='center'
                    gap='8px'
                  >
                    <ToolIcon icon={option.tool.attributes.icon} size='24px' iconSize='14px' />
                    <Text>{option.label}</Text>
                  </Flex>
                )}
                chakraStyles={{
                  container: (provided) => ({ ...provided, width: '100%' }),
                }}
              />
            </Box>
          </FormControl>

          {/* Section 3: Tools list (only when a tool is selected) */}
          {selectedTool && (
            <FormControl>
              <Flex alignItems='center' justifyContent='space-between' mb='8px'>
                <Flex alignItems='center' gap='4px'>
                  <FormLabel fontSize='sm' fontWeight={600} m='0'>
                    Tools
                  </FormLabel>
                  <ToolTip label='Select which actions this tool connection can perform'>
                    <FiInfo size='14px' color='gray' />
                  </ToolTip>
                </Flex>
                <Flex gap='8px'>
                  <Button
                    variant='ghost'
                    size='sm'
                    onClick={handleSelectAll}
                    fontSize='12px'
                    fontWeight={500}
                    height='24px'
                    padding='0px 8px'
                    isDisabled={allSelected}
                  >
                    Select All
                  </Button>
                  <Button
                    variant='ghost'
                    size='sm'
                    onClick={handleDeselectAll}
                    fontSize='12px'
                    fontWeight={500}
                    height='24px'
                    padding='0px 8px'
                    isDisabled={!someSelected && !allSelected}
                  >
                    Deselect All
                  </Button>
                </Flex>
              </Flex>
              {isLoadingActions ? (
                <Loader />
              ) : (
                <Flex
                  direction='column'
                  border='1px solid'
                  borderColor='gray.400'
                  borderRadius='8px'
                >
                  {toolActions.map((action) => (
                    <Flex
                      key={action.name}
                      alignItems='center'
                      justifyContent='space-between'
                      borderBottom='1px solid'
                      borderColor='gray.400'
                      paddingX='20px'
                      paddingY='12px'
                    >
                      <Box flex='1' mr='12px'>
                        <Text fontSize='sm' fontWeight={600} textTransform='capitalize'>
                          {action.name.replace(/_/g, ' ')}
                        </Text>
                        <Text fontSize='xs' color='black.100' letterSpacing='-1%'>
                          {action.description}
                        </Text>
                      </Box>
                      <Switch
                        isChecked={isActionChecked(action.name)}
                        onChange={() => handleActionToggle(action.name)}
                        colorScheme='brand'
                      />
                    </Flex>
                  ))}
                </Flex>
              )}
            </FormControl>
          )}
        </Flex>
      </BaseModal>
    </Box>
  );
};

export default ToolSelectorWidget;
