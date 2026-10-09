import { useMemo } from 'react';
import {
  Box,
  Flex,
  Text,
  Button,
  Icon,
  Accordion,
  AccordionItem,
  AccordionButton,
  AccordionPanel,
  AccordionIcon,
  Badge,
} from '@chakra-ui/react';
import { FiRefreshCcw } from 'react-icons/fi';
import BaseModal from '@/components/BaseModal';
import FiAiCard from '@/assets/icons/FiAICard';
import { FlowComponent } from '../../types';
import { AgentVersion } from '@/enterprise/store/useAgentStore';

interface ChangeItem {
  id: string;
  name: string;
  type: 'added' | 'updated' | 'removed';
  details?: string;
}

interface VersionDiffModalProps {
  isOpen: boolean;
  onClose: () => void;
  previewVersion: AgentVersion;
  currentVersionNumber?: number;
  currentVersionStatus?: 'draft' | 'published';
  originalComponents?: FlowComponent[];
  onRestore: () => void;
  onBackToDraft: () => void;
}

// Compute differences between original draft components and preview version components
const computeChanges = (
  originalComponents: FlowComponent[] | undefined,
  previewComponents: FlowComponent[] | undefined,
): ChangeItem[] => {
  if (!originalComponents || !previewComponents) {
    return [];
  }

  const changes: ChangeItem[] = [];
  const originalMap = new Map(originalComponents.map((c) => [c.id, c]));
  const previewMap = new Map(previewComponents.map((c) => [c.id, c]));

  // Find removed components (in original but not in preview)
  originalComponents.forEach((original) => {
    if (!previewMap.has(original.id)) {
      changes.push({
        id: original.id,
        name: original.data?.label || original.component_type || 'Component',
        type: 'removed',
        details: `Component "${original.data?.label || original.id}" was removed in the preview version.`,
      });
    }
  });

  // Find added components (in preview but not in original)
  previewComponents.forEach((preview) => {
    if (!originalMap.has(preview.id)) {
      changes.push({
        id: preview.id,
        name: preview.data?.label || preview.component_type || 'Component',
        type: 'added',
        details: `Component "${preview.data?.label || preview.id}" was added in the preview version.`,
      });
    }
  });

  // Find updated components (in both but with different configurations)
  previewComponents.forEach((preview) => {
    const original = originalMap.get(preview.id);
    if (original) {
      // Compare configurations
      const originalConfig = JSON.stringify(original.configuration || {}, null, 2);
      const previewConfig = JSON.stringify(preview.configuration || {}, null, 2);

      if (originalConfig !== previewConfig) {
        changes.push({
          id: preview.id,
          name: preview.data?.label || preview.component_type || 'Component',
          type: 'updated',
          details: `Configuration changed:\n\nCurrent Draft:\n${originalConfig}\n\nPreview Version:\n${previewConfig}`,
        });
      }
    }
  });

  return changes;
};

const VersionDiffModal = ({
  isOpen,
  onClose,
  previewVersion,
  currentVersionNumber,
  currentVersionStatus = 'draft',
  originalComponents,
  onRestore,
  onBackToDraft,
}: VersionDiffModalProps) => {
  const previewComponents = previewVersion?.configuration?.components;

  // Compute actual changes between original draft and preview version
  const changes = useMemo(
    () => computeChanges(originalComponents, previewComponents),
    [originalComponents, previewComponents],
  );

  const currentVersion = currentVersionNumber ? `v${currentVersionNumber}` : 'Draft';
  const currentVersionLabel = currentVersionStatus === 'published' ? 'live' : 'draft';

  return (
    <BaseModal
      openModal={isOpen}
      setModalOpen={onClose}
      title=''
      modalWidth='2xl'
      addFooterStroke
      showCloseButton={false}
      footer={
        <Box width='100%'>
          <Text fontSize='14px' color='black.100' lineHeight='20px'>
            Viewing changes between the {currentVersionLabel} version{' '}
            <Box
              as='span'
              px='8px'
              py='2px'
              border='1px solid'
              borderRadius='4px'
              borderColor='gray.500'
              bg='gray.200'
              fontWeight='600'
              color='black.300'
            >
              {currentVersion}
            </Box>{' '}
            and this version{' '}
            <Box
              as='span'
              px='8px'
              py='2px'
              border='1px solid'
              borderRadius='4px'
              borderColor='gray.500'
              bg='gray.200'
              fontWeight='600'
              color='black.300'
            >
              {previewVersion.versionNumber}
            </Box>
          </Text>
          <Box mt='16px'>
            <Flex
              justifyContent='space-between'
              alignItems='center'
              bg='gray.300'
              p='12px'
              borderRadius='6px'
              fontSize='12px'
              color='black.500'
              border='1px solid'
              borderColor='gray.400'
            >
              <Text fontSize='14px' color='gray.600' fontWeight='600' lineHeight='20px'>
                Version Description
              </Text>
              <Text fontSize='14px' color='black.500' fontWeight='400' lineHeight='20px'>
                {previewVersion.description || 'No description'}
              </Text>
            </Flex>
          </Box>

          <Flex gap='12px' width='100%' mt='16px'>
            <Button
              variant='outline'
              flex='1'
              onClick={onBackToDraft}
              bg='gray.100'
              borderColor='gray.400'
              color='black.500'
              fontSize='14px'
              fontWeight='700'
              lineHeight='20px'
              _hover={{ bg: 'gray.200' }}
            >
              Back to current draft
            </Button>
            <Button
              flex='1'
              bg='primary.400'
              color='gray.100'
              leftIcon={<Icon as={FiRefreshCcw} />}
              onClick={onRestore}
              _hover={{ bg: 'primary.500' }}
              fontSize='14px'
              fontWeight='700'
              lineHeight='20px'
              data-testid='workflow-version-replace-draft-button'
            >
              Replace draft with this version
            </Button>
          </Flex>
        </Box>
      }
    >
      <Box mb='64px'>
        {changes.length === 0 ? (
          <Flex
            justify='center'
            align='center'
            height='120px'
            bg='gray.50'
            borderRadius='8px'
            border='1px solid'
            borderColor='gray.400'
          >
            <Text fontSize='14px' color='gray.600'>
              No component changes detected between versions
            </Text>
          </Flex>
        ) : (
          <Accordion allowMultiple>
            {changes.map((change) => (
              <AccordionItem
                key={change.id}
                border='1px solid'
                borderColor='gray.400'
                borderRadius='8px'
                mb='12px'
                overflow='hidden'
                _hover={{ borderColor: 'gray.500' }}
              >
                <AccordionButton p='12px 16px'>
                  <Flex flex='1' textAlign='left' align='center' gap='12px'>
                    <Box
                      w='32px'
                      h='32px'
                      bg='warning.100'
                      borderRadius='6px'
                      p='8px'
                      display='flex'
                      alignItems='center'
                      justifyContent='center'
                    >
                      <Icon as={FiAiCard} color='warning.500' />
                    </Box>
                    <Text fontWeight='600' fontSize='14px' color='black.500' lineHeight='20px'>
                      {change.name}
                    </Text>
                  </Flex>
                  <Flex align='center' gap='12px'>
                    <Badge
                      variant='subtle'
                      color={
                        change.type === 'added'
                          ? 'success.600'
                          : change.type === 'updated'
                            ? 'black.300'
                            : 'error.600'
                      }
                      colorScheme={
                        change.type === 'added'
                          ? 'success'
                          : change.type === 'updated'
                            ? 'gray.200'
                            : 'error'
                      }
                      border='1px solid'
                      borderColor={
                        change.type === 'added'
                          ? 'success.300'
                          : change.type === 'updated'
                            ? 'gray.500'
                            : 'error.300'
                      }
                      borderRadius='4px'
                      fontSize='12px'
                      lineHeight='16px'
                      px='8px'
                      py='2px'
                    >
                      {change.type.toUpperCase()}
                    </Badge>
                    <AccordionIcon />
                  </Flex>
                </AccordionButton>
                <AccordionPanel pb={4} pt={0} bg='gray.50'>
                  {change.details ? (
                    <Box
                      as='pre'
                      fontSize='12px'
                      fontFamily='mono'
                      p='12px'
                      bg={
                        change.type === 'added'
                          ? 'green.50'
                          : change.type === 'removed'
                            ? 'red.50'
                            : 'blue.50'
                      }
                      color='black.500'
                      whiteSpace='pre-wrap'
                      borderRadius='4px'
                      borderLeft='4px solid'
                      borderColor={
                        change.type === 'added'
                          ? 'green.400'
                          : change.type === 'removed'
                            ? 'red.400'
                            : 'blue.400'
                      }
                    >
                      {change.details}
                    </Box>
                  ) : (
                    <Text fontSize='12px' color='gray.600' fontStyle='italic'>
                      No specific details shown for this change in preview.
                    </Text>
                  )}
                </AccordionPanel>
              </AccordionItem>
            ))}
          </Accordion>
        )}
      </Box>
    </BaseModal>
  );
};

export default VersionDiffModal;
