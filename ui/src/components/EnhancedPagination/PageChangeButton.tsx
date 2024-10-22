import { Button, Icon } from '@chakra-ui/react';
import { FiChevronLeft, FiChevronRight, FiChevronsLeft, FiChevronsRight } from 'react-icons/fi';

export enum PAGE_CHANGE_BUTTON_TYPE {
  PREVIOUS = 'previous',
  NEXT = 'next',
  FIRST = 'first',
  LAST = 'last',
}

type PageButtonProps = {
  type: PAGE_CHANGE_BUTTON_TYPE;
  onClick: () => void;
  isEnabled?: boolean;
};

const PageChangeButton = ({ type, onClick, isEnabled = false }: PageButtonProps) => {
  const iconMap = {
    [PAGE_CHANGE_BUTTON_TYPE.PREVIOUS]: { icon: FiChevronLeft, value: 'previous' },
    [PAGE_CHANGE_BUTTON_TYPE.FIRST]: { icon: FiChevronsLeft, value: 'first' },
    [PAGE_CHANGE_BUTTON_TYPE.LAST]: { icon: FiChevronsRight, value: 'last' },
    [PAGE_CHANGE_BUTTON_TYPE.NEXT]: { icon: FiChevronRight, value: 'next' },
  };

  const icon = iconMap[type] || iconMap[PAGE_CHANGE_BUTTON_TYPE.NEXT];

  return (
    <Button
      height='32px'
      width='32px'
      borderRadius='6px'
      borderStyle='solid'
      borderWidth='1px'
      borderColor='gray.500'
      display='flex'
      justifyContent='center'
      alignItems='center'
      color='black.200'
      backgroundColor='gray.300'
      minWidth='0'
      padding={0}
      onClick={onClick}
      _hover={{ backgroundColor: 'gray.400' }}
      _disabled={{
        _hover: { cursor: 'not-allowed' },
        backgroundColor: 'gray.400',
      }}
      isDisabled={!isEnabled}
      data-testid={`page-change-${icon.value}`}
    >
      <Icon as={icon.icon} h='14px' w='14px' color='black.500' />
    </Button>
  );
};

export default PageChangeButton;
