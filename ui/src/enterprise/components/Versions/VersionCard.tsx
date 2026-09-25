import { Avatar, Badge, Box, Flex, IconButton, Text } from '@chakra-ui/react';
import { FiEye, FiUser } from 'react-icons/fi';
import type { ReactNode } from 'react';
import ToolTip from '@/components/ToolTip';
import { formatTimestamp } from '@/utils/formatTimestamp';
import VersionActionsMenu from './VersionActionsMenu';

export type VersionDisplayStatus = 'draft' | 'live' | 'archived';

export interface VersionCardDisplay {
  label: string;
  status: VersionDisplayStatus;
  description: string;
  author: string | null;
  timestamp: string | null;
  canPreview: boolean;
  canEdit: boolean;
  canDelete: boolean;
  showActions?: boolean;
}

interface VersionCardProps {
  version: VersionCardDisplay;
  testId: string;
  versionNumber: string | number;
  isLatestPublished?: boolean;
  actions?: ReactNode;
  previewButtonTestId?: string;
  onPreview: () => void;
  onEditDescription: () => void;
  onDelete: () => void;
}

const STATUS_CONFIG = {
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
    label: '',
  },
} as const;

const VersionCard = ({
  version,
  testId,
  versionNumber,
  isLatestPublished,
  actions,
  previewButtonTestId,
  onPreview,
  onEditDescription,
  onDelete,
}: VersionCardProps): JSX.Element => {
  const config = STATUS_CONFIG[version.status];
  const timestamp = version.timestamp ? formatTimestamp(version.timestamp, true) : '';

  return (
    <Box
      data-testid={testId}
      data-version-number={versionNumber}
      data-latest-published={isLatestPublished}
      p='16px 20px'
      borderWidth='1px'
      borderColor='gray.400'
      borderRadius='8px'
      bg='white'
      position='relative'
      transition='all 0.2s'
      _hover={{ borderColor: 'gray.500', shadow: 'sm' }}
    >
      <Flex justify='space-between' align='center' mb='8px' minH='24px'>
        <Flex align='center' gap='8px'>
          <Text fontWeight='600' fontSize='14px' lineHeight='20px' color='black.500'>
            {version.label}
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
          {version.canPreview && (
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
                data-testid={previewButtonTestId}
                onClick={(event) => {
                  event.stopPropagation();
                  onPreview();
                }}
                _hover={{ bg: 'gray.100', color: 'black.500' }}
              />
            </ToolTip>
          )}
          {actions ??
            (version.showActions !== false && (
              <VersionActionsMenu
                onEditDescription={onEditDescription}
                onDelete={onDelete}
                canEdit={version.canEdit}
                canDelete={version.canDelete}
              />
            ))}
        </Flex>
      </Flex>

      <Text fontSize='12px' lineHeight='18px' color='black.100' mb='16px' noOfLines={2}>
        {version.description}
      </Text>

      <Flex justify='space-between' align='center' borderTop='1px' borderColor='gray.400' pt='16px'>
        <Flex align='center' gap='8px'>
          <Avatar
            size='xs'
            name={version.author ?? undefined}
            bg='gray.300'
            borderColor='gray.400'
            color='black.100'
            w='24px'
            h='24px'
            icon={<FiUser size='12px' />}
          />
          {version.author ? (
            <ToolTip label={version.author}>
              <Text
                fontSize='14px'
                lineHeight='20px'
                color='black.100'
                maxW='6rem'
                overflow='hidden'
                textOverflow='ellipsis'
                whiteSpace='nowrap'
              >
                {version.author}
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
