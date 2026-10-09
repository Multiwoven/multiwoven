import { Icon, IconButton, Menu, MenuButton, MenuItem, MenuList } from '@chakra-ui/react';
import { FiEdit2, FiMoreVertical, FiTrash2 } from 'react-icons/fi';

export interface VersionActionsMenuProps {
  onEditDescription: () => void;
  onDelete: () => void;
  canEdit?: boolean;
  canDelete?: boolean;
  menuButtonTestId?: string;
  deleteButtonTestId?: string;
}

const VersionActionsMenu = ({
  onEditDescription,
  onDelete,
  canEdit = true,
  canDelete = false,
  menuButtonTestId = 'workflow-version-menu-button',
  deleteButtonTestId = 'workflow-version-delete-button',
}: VersionActionsMenuProps): JSX.Element => (
  <Menu placement='bottom-end'>
    <MenuButton
      as={IconButton}
      aria-label='Version options'
      icon={<Icon as={FiMoreVertical} boxSize='24px' p='4px' color='black.500' />}
      h='24px'
      w='24px'
      bg='transparent'
      minW='auto'
      _hover={{ bg: 'gray.100' }}
      data-testid={menuButtonTestId}
      onClick={(event) => event.stopPropagation()}
    />
    <MenuList minW='180px' p='4px' borderRadius='12px' borderColor='gray.200' boxShadow='lg'>
      <MenuItem
        icon={<Icon as={FiEdit2} boxSize='14px' />}
        onClick={(event) => {
          event.stopPropagation();
          onEditDescription();
        }}
        fontSize='sm'
        borderRadius='8px'
        _hover={{ bg: 'gray.50' }}
        color='gray.700'
        px='12px'
        py='8px'
        isDisabled={!canEdit}
      >
        Edit Description
      </MenuItem>
      <MenuItem
        icon={<Icon as={FiTrash2} boxSize='14px' />}
        onClick={(event) => {
          event.stopPropagation();
          onDelete();
        }}
        fontSize='sm'
        borderRadius='8px'
        _hover={{ bg: 'red.50' }}
        color='red.500'
        isDisabled={!canDelete}
        px='12px'
        py='8px'
        data-testid={deleteButtonTestId}
      >
        Delete
      </MenuItem>
    </MenuList>
  </Menu>
);

export default VersionActionsMenu;
