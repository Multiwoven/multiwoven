import { Tag, Text } from '@chakra-ui/react';

const StatusTag = ({ status }: { status: string }) => (
  <Tag
    colorScheme='teal'
    size='xs'
    bgColor='success.100'
    paddingX={2}
    fontWeight={600}
    borderColor='success.300'
    borderWidth='1px'
    borderStyle='solid'
    height='22px'
    borderRadius='4px'
  >
    <Text size='xs' fontWeight='semibold' color='success.600'>
      {status}
    </Text>
  </Tag>
);

export default StatusTag;
