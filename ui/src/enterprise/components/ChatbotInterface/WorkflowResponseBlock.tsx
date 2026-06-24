import React, { useState } from 'react';
import { Box, Flex, Icon, Image, Skeleton, Text } from '@chakra-ui/react';
import AlertBox from '@/components/Alerts';
import { FiChevronDown, FiChevronUp, FiLoader, FiShare2 } from 'react-icons/fi';
import { WorkflowResponseData } from './types';
import { getCategoryBaseColor } from '@/enterprise/views/Agents/AgentWorkflow/Configbar/utils';
import StatusTag, { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';
import MissingConnectionCard from './MissingConnectionCard';
import ConnectSourceDrawer from './ConnectSourceDrawer';

type ComponentStatus = 'added' | 'modified' | 'deleted';

type ComponentWithStatus = {
  label: string;
  icon: string;
  status: ComponentStatus;
  category: string;
};

const STATUS_VARIANT_MAP: Record<ComponentStatus, StatusTagVariants> = {
  added: StatusTagVariants.success,
  modified: StatusTagVariants.pending,
  deleted: StatusTagVariants.failed,
};

interface WorkflowResponseBlockProps {
  workflowData?: WorkflowResponseData;
  loading?: boolean;
  didLoad?: boolean;
  onRevert?: () => void;
  onRetryPrompt?: () => void;
}

const WorkflowResponseBlock: React.FC<WorkflowResponseBlockProps> = ({
  workflowData,
  loading,
  didLoad,
  onRetryPrompt,
}) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [connectedSources, setConnectedSources] = useState<Set<string>>(new Set());
  const [activeConnector, setActiveConnector] = useState<{ name: string; category: string } | null>(
    null,
  );

  if (loading) {
    return (
      <Box w='100%' maxW='440px'>
        <Flex
          flexDir='row'
          align='center'
          h='48px'
          p='8px'
          gap='12px'
          border='1px solid'
          borderColor='gray.400'
          borderRadius='8px'
          bg='white'
        >
          <Flex
            w='32px'
            h='32px'
            flexShrink={0}
            align='center'
            justify='center'
            border='1px solid'
            borderColor='gray.400'
            borderRadius='6px'
            bg='white'
          >
            <Icon
              as={FiLoader}
              boxSize='16px'
              color='gray.600'
              sx={{
                '@keyframes spin': {
                  from: { transform: 'rotate(0deg)' },
                  to: { transform: 'rotate(360deg)' },
                },
                animation: 'spin 1s linear infinite',
              }}
            />
          </Flex>
          <Skeleton flex={1} h='10px' borderRadius='2px' />
        </Flex>
      </Box>
    );
  }

  if (!workflowData) {
    return (
      <Box w='100%' maxW='440px'>
        <AlertBox
          title='Unable to display workflow'
          description='The workflow response could not be loaded.'
          status='error'
        />
      </Box>
    );
  }

  const missingConnectors = workflowData.meta?.missing_connectors ?? [];

  if (missingConnectors.length > 0) {
    return (
      <Box w='100%' maxW='440px'>
        <Flex flexDir='column' gap='8px'>
          {missingConnectors.map((connector) => (
            <MissingConnectionCard
              key={connector.name}
              connectorName={connector.name}
              isConnected={connectedSources.has(connector.name)}
              onConnectClick={() => setActiveConnector(connector)}
              onRetryPrompt={onRetryPrompt}
              didLoad={didLoad}
            />
          ))}
        </Flex>
        {activeConnector && (
          <ConnectSourceDrawer
            isOpen={true}
            connectorName={activeConnector.name}
            connectorType={activeConnector.category}
            onClose={() => setActiveConnector(null)}
            onSuccess={() => {
              setConnectedSources((prev) => new Set(prev).add(activeConnector.name));
              setActiveConnector(null);
            }}
          />
        )}
      </Box>
    );
  }

  if (!workflowData.data) {
    return (
      <Box w='100%' maxW='440px'>
        <AlertBox
          title='Unable to display workflow'
          description='The workflow response could not be loaded.'
          status='error'
        />
      </Box>
    );
  }

  const { meta } = workflowData;
  const safeChanges = meta?.changes ?? { added: [], modified: [], deleted: [] };

  // Collect components that changed, preserving order: added → modified → deleted
  const changedComponents: ComponentWithStatus[] = [
    ...safeChanges.added.map((comp) => ({
      label: comp.data.label,
      icon: comp.data.icon,
      category: comp.data.category,
      status: 'added' as ComponentStatus,
    })),
    ...safeChanges.modified.map((comp) => ({
      label: comp.data.label,
      icon: comp.data.icon,
      category: comp.data.category,
      status: 'modified' as ComponentStatus,
    })),
    ...safeChanges.deleted.map((comp) => ({
      label: comp.data.label,
      icon: comp.data.icon,
      category: comp.data.category,
      status: 'deleted' as ComponentStatus,
    })),
  ];

  return (
    <Box w='100%' maxW='440px' data-testid='generated-workflow'>
      <Flex
        flexDir='column'
        border='1px solid'
        borderColor='gray.400'
        borderRadius='8px'
        overflow='hidden'
        bg='white'
        padding='8px'
        gap='16px'
      >
        {/* Header row */}
        <Flex
          align='center'
          gap='8px'
          borderBottom={isExpanded ? '1px solid' : ''}
          borderColor='gray.400'
          paddingBottom={isExpanded ? '8px' : ''}
        >
          <Flex
            width='32px'
            height='32px'
            alignItems='center'
            justifyContent='center'
            border='1px solid'
            borderColor='gray.400'
            borderRadius='6px'
          >
            <Icon as={FiShare2} boxSize='16px' color='black.500' flexShrink={0} />
          </Flex>
          <Text flex={1} fontSize='sm' fontWeight={600} color='black.500'>
            Generated workflow
          </Text>
          {changedComponents.length > 0 && (
            <Box
              as='button'
              p='4px'
              borderRadius='4px'
              onClick={() => setIsExpanded((prev) => !prev)}
              aria-label={isExpanded ? 'Collapse' : 'Expand'}
              opacity={0.6}
              _hover={{ opacity: 1 }}
            >
              <Icon as={isExpanded ? FiChevronUp : FiChevronDown} />
            </Box>
          )}
        </Flex>

        {/* Expanded: additional workflow details */}
        {isExpanded && (
          <>
            <Text
              fontSize='xs'
              fontWeight='bold'
              color='gray.600'
              letterSpacing='wider'
              textTransform='uppercase'
              px='8px'
            >
              Components
            </Text>
            <Flex flexDir='column' gap='8px'>
              {changedComponents.map((comp, idx) => (
                <Flex
                  key={idx}
                  align='center'
                  gap='12px'
                  padding='8px'
                  border='1px solid'
                  borderColor='gray.400'
                  borderRadius='8px'
                >
                  {/* Component icon */}
                  <Flex
                    justifyContent='center'
                    alignItems='center'
                    height='32px'
                    width='32px'
                    borderRadius='6px'
                    border='1px solid'
                    borderColor={`${getCategoryBaseColor(comp.category)}.200`}
                    backgroundColor={`${getCategoryBaseColor(comp.category)}.100`}
                    color={`${getCategoryBaseColor(comp.category)}.400`}
                  >
                    <Image src={comp.icon} h='20px' w='20px' />
                  </Flex>

                  {/* Component label */}
                  <Text flex={1} fontSize='sm' color='black.500' fontWeight={600}>
                    {comp.label}
                  </Text>

                  {/* Status badge */}
                  <StatusTag
                    variant={STATUS_VARIANT_MAP[comp.status]}
                    status={StatusTagText[comp.status]}
                  />
                </Flex>
              ))}
            </Flex>
          </>
        )}
      </Flex>
    </Box>
  );
};

export default WorkflowResponseBlock;
