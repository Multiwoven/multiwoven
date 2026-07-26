import { Box, Flex, Text, Badge, Avatar, IconButton } from '@chakra-ui/react';
import { FiEye, FiUser } from 'react-icons/fi';
import { WorkflowVersionResponse } from '@/enterprise/services/types';
import VersionActionsMenu from './VersionActionsMenu';
import ToolTip from '@/components/ToolTip';
import { formatTimestamp } from '@/utils/formatTimestamp';

interface VersionCardProps {
  version: WorkflowVersionResponse;
  isCurrent: boolean;
  isLatestPublished?: boolean;
  onPreview: () => void;
  onEditDescription: () => void;
  onDelete: () => void;
}

const VersionCard = ({
  version,
  isCurrent,
  isLatestPublished = false,
  onPreview,
  onEditDescription,
  onDelete,
}: VersionCardProps) => {
  // Get the version's status from the nested workflow object
  const versionStatus = version.attributes.workflow?.attributes?.status;

  // Determine display status: Live if published, Draft if current and draft, otherwise archived
  const status: 'draft' | 'live' | 'archived' = isLatestPublished
    ? 'live'
    : isCurrent && versionStatus === 'draft'
      ? 'draft'
      : 'archived';

  const statusConfig = {
    draft: {
      bg: 'info.100',
      color: 'info.600',
      borderColor: 'info.300',
      label: 'Draft',
    },
    live: {
      bg: 'success.100',
      color: 'success.600',
      borderColor: 'success.300',
      label: 'Live',
    },
    archived: {
      bg: 'gray.100',
      color: 'gray.600',
      borderColor: 'gray.200',
      label: '', // No badge for archived based on design
    },
  };

  const config = statusConfig[status];

  // Format display values from API response
  const versionNumber = `v${version.attributes.version_number}`;
  const description = version.attributes.version_description || '';
  const timestamp = version.attributes.created_at
    ? formatTimestamp(version.attributes.created_at, true)
    : '';
  const author = version.attributes.whodunnit;

  return (
    <Box
      data-testid='workflow-version-item'
      data-version-number={version.attributes.version_number}
      p='16px 20px'
      borderWidth='1px'
      borderColor='gray.400'
      borderRadius='8px'
      bg='white'
      position='relative'
      transition='all 0.2s'
      _hover={{ borderColor: 'gray.500', shadow: 'sm' }}
      data-latest-published={isLatestPublished}
    >
      <Flex justify='space-between' align='center' mb='8px'>
        <Flex align='center' gap='8px'>
          <Text fontWeight='600' fontSize='14px' lineHeight='20px' color='black.500'>
            {versionNumber}
          </Text>
          {config.label && (
            <Badge
              bg={config.bg}
              color={config.color}
              border='1px solid'
              borderColor={config.borderColor}
              fontSize='12px'
              lineHeight='18px'
              fontWeight='600'
              px='8px'
              py='2px'
              borderRadius='4px'
              textTransform='capitalize'
              display='flex'
              alignItems='center'
              height='22px'
            >
              {config.label}
            </Badge>
          )}
        </Flex>
        <Flex align='center' gap='6px'>
          {!isCurrent && (
            <ToolTip label='Preview Version'>
              <IconButton
                aria-label='Preview Version'
                icon={<FiEye size='16px' />}
                variant='ghost'
                w='24px'
                h='24px'
                minW='24px'
                p='0'
                borderRadius='6px'
                border='none'
                bg='transparent'
                color='gray.600'
                onClick={(e: React.MouseEvent) => {
                  e.stopPropagation();
                  onPreview();
                }}
                _hover={{ bg: 'gray.100', color: 'black.500' }}
              />
            </ToolTip>
          )}
          <VersionActionsMenu
            isPublished={status === 'live'}
            isCurrent={isCurrent}
            onEditDescription={onEditDescription}
            onDelete={onDelete}
          />
        </Flex>
      </Flex>

      <Text fontSize='12px' lineHeight='18px' color='black.100' mb='16px' noOfLines={2}>
        {description}
      </Text>

      <Flex justify='space-between' align='center' borderTop='1px' borderColor='gray.400' pt='16px'>
        <Flex align='center' gap='8px'>
          <Avatar
            size='xs'
            name={author}
            bg='gray.300'
            borderColor='gray.400'
            color='black.100'
            w='24px'
            h='24px'
            icon={<FiUser size='12px' />}
          />
          {author ? (
            <ToolTip label={author}>
              <Text
                fontSize='14px'
                lineHeight='20px'
                color='black.100'
                maxW='6rem'
                overflow='hidden'
                textOverflow='ellipsis'
                whiteSpace='nowrap'
              >
                {author}
              </Text>
            </ToolTip>
          ) : (
            <Text fontSize='14px' lineHeight='20px' color='black.100'>
              -
            </Text>
          )}
        </Flex>
        {timestamp && (
          <Text fontSize='12px' lineHeight='18px' color='black.100'>
            {timestamp}
          </Text>
        )}
      </Flex>
    </Box>
  );
};

export default VersionCard;
