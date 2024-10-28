import { Box, Text } from '@chakra-ui/react';

const PageNumberItem = ({
  isActive = false,
  onClick,
  value,
  isEllipsis = false,
}: {
  isActive?: boolean;
  onClick?: () => void;
  value?: number;
  isEllipsis?: boolean;
}) => (
  <Box
    height='32px'
    width='32px'
    borderRadius='6px'
    borderStyle='solid'
    borderWidth={isActive ? '1px' : '0px'}
    borderColor={isActive ? 'gray.500' : 'gray.400'}
    display='flex'
    justifyContent='center'
    alignItems='center'
    color='black.200'
    backgroundColor={isActive ? 'gray.100' : 'gray.300'}
    minWidth='0'
    padding={0}
    onClick={isEllipsis ? () => {} : onClick}
    _hover={{ backgroundColor: 'gray.400', cursor: 'pointer' }}
    _disabled={{
      _hover: { cursor: 'not-allowed' },
      backgroundColor: 'gray.400',
    }}
    data-testid={isEllipsis ? 'ellipsis' : `page-number-${value}`}
  >
    <Text size='xs' fontWeight='semibold'>
      {isEllipsis ? '...' : value}
    </Text>
  </Box>
);

export default PageNumberItem;
