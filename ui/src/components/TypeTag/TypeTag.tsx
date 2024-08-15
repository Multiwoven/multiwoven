import { Tag, Text, Icon, Box } from '@chakra-ui/react';
import { IconType } from 'react-icons/lib';

type TypeTagProps = {
  label: string;
  leftIcon?: IconType;
};

const TypeTag = ({ label, leftIcon }: TypeTagProps) => (
  <Tag
    colorScheme='teal'
    size='xs'
    bgColor='gray.200'
    paddingX={2}
    fontWeight={600}
    borderColor='gray.500'
    borderWidth='1px'
    borderStyle='solid'
    height='22px'
    borderRadius='4px'
  >
    <Box display='flex' gap='4px' alignItems='center'>
      <Icon as={leftIcon} color='black.300' />
      <Text size='xs' fontWeight='semibold' color='black.300'>
        {label}
      </Text>
    </Box>
  </Tag>
);

export default TypeTag;
