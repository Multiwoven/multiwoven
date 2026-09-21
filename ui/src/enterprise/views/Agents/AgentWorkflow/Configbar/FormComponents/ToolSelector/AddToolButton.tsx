import { Flex, Icon, Text } from '@chakra-ui/react';
import { FiPlus, FiSettings } from 'react-icons/fi';

interface AddToolButtonProps {
  onClick: () => void;
}

const AddToolButton = ({ onClick }: AddToolButtonProps) => (
  <Flex
    data-testid='workflow-tool-add-button'
    padding='8px'
    border='1px solid'
    borderColor='gray.400'
    borderRadius='8px'
    backgroundColor='gray.200'
    cursor='pointer'
    alignItems='center'
    justifyContent='space-between'
    gap='12px'
    width='320px'
    height='48px'
    _hover={{ backgroundColor: 'gray.300' }}
    onClick={onClick}
  >
    <Flex alignItems='center' gap='8px' width='105px' height='32px' flex='none'>
      <Flex
        width='32px'
        height='32px'
        backgroundColor='white'
        border='1px solid'
        borderColor='gray.400'
        borderRadius='6px'
        alignItems='center'
        justifyContent='center'
        position='relative'
        flex='none'
      >
        <Icon as={FiPlus} color='black.300' boxSize='16px' />
      </Flex>
      <Text
        fontSize='14px'
        fontWeight={600}
        color='black.500'
        lineHeight='20px'
        letterSpacing='-0.01em'
        width='65px'
        height='20px'
        flex='none'
      >
        Add a tool
      </Text>
    </Flex>
    <Flex
      alignItems='center'
      justifyContent='center'
      padding='0px 8px'
      gap='6px'
      width='24px'
      height='24px'
      opacity={0.5}
      borderRadius='6px'
      flex='none'
    >
      <Icon as={FiSettings} color='gray.600' boxSize='16px' />
    </Flex>
  </Flex>
);

export default AddToolButton;
