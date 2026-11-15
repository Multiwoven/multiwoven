import { Box, Flex, Icon, Text } from '@chakra-ui/react';
import type { KeyboardEvent, MouseEvent } from 'react';
import { FiFolder, FiTrash2 } from 'react-icons/fi';

import TypeTag from '@/components/TypeTag';

import type { Folder } from './types';

type FolderCardProps = {
  folder: Folder;
  onClick?: () => void;
  /** Render a hover-revealed trash icon if provided. */
  onDelete?: () => void;
};

export function FolderCard({ folder, onClick, onDelete }: FolderCardProps): JSX.Element {
  const handleDeleteClick = (e: MouseEvent<HTMLButtonElement>): void => {
    // Stop propagation so the row's onClick (which navigates into the folder)
    // doesn't fire when the user clicks the trash.
    e.stopPropagation();
    onDelete?.();
  };

  // The outer card is intentionally a `<div role="button">` rather than a
  // `<button>`. The hover-revealed trash inside is its own `<button>`, and
  // `<button>` nested in `<button>` is invalid HTML — using a role here
  // keeps the markup valid while preserving keyboard activation.
  const handleKeyDown = (e: KeyboardEvent<HTMLDivElement>): void => {
    if (!onClick) return;
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onClick();
    }
  };

  return (
    <Flex
      role='button'
      tabIndex={onClick ? 0 : -1}
      onClick={onClick}
      onKeyDown={handleKeyDown}
      data-testid={`app-builder-folder-${folder.name}`}
      // `className='group'` keeps the hover-reveal trash working — Chakra's
      // `_groupHover` selector matches `.group:hover &` in addition to
      // `[role=group]`, and we can't use role='group' here because
      // role='button' (for the card) already occupies that slot.
      className='group'
      align='center'
      justify='space-between'
      bg='gray.200'
      borderWidth='1px'
      borderColor='gray.400'
      borderRadius='8px'
      pl='8px'
      pr='12px'
      py='8px'
      gap='8px'
      transition='background 0.15s, border-color 0.15s'
      _hover={{ bg: 'gray.300', borderColor: 'gray.400' }}
      cursor={onClick ? 'pointer' : 'default'}
      textAlign='left'
    >
      <Flex align='center' gap='8px' minW={0}>
        <Flex
          align='center'
          justify='center'
          w='32px'
          h='32px'
          bg='gray.100'
          borderWidth='1px'
          borderColor='gray.400'
          borderRadius='6px'
          flexShrink={0}
        >
          <Icon as={FiFolder} boxSize='16px' color='black.500' />
        </Flex>
        <Text fontSize='sm' fontWeight='semibold' color='black.500' lineHeight='20px' noOfLines={1}>
          {folder.name}
        </Text>
      </Flex>

      <Flex align='center' gap='8px' flexShrink={0}>
        <TypeTag label={folder.is_public ? 'Public' : 'Private'} />
        {onDelete && (
          // Hover-only delete affordance — just the bare icon (no IconButton
          // background / padding) per Figma. The parent row's `role='group'`
          // drives the opacity fade.
          <Box
            as='button'
            aria-label={`Delete folder ${folder.name}`}
            data-testid={`app-builder-delete-folder-${folder.name}`}
            onClick={handleDeleteClick}
            color='gray.600'
            cursor='pointer'
            opacity={0}
            _groupHover={{ opacity: 1 }}
            _hover={{ color: 'black.500' }}
            transition='opacity 0.15s, color 0.15s'
            display='flex'
            alignItems='center'
          >
            <Icon as={FiTrash2} boxSize='14px' />
          </Box>
        )}
      </Flex>
    </Flex>
  );
}
