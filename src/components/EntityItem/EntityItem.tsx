import { Box, Image, Text } from '@chakra-ui/react';

type EntityItem = {
  icon: string;
  name: string;
};

const EntityItem = ({ icon, name }: EntityItem): JSX.Element => {
  return (
    <Box display='flex' alignItems='center'>
      <Box
        height='40px'
        width='40px'
        marginRight='12px'
        borderWidth='1px'
        borderColor='gray.400'
        padding='3px'
        borderRadius='8px'
        backgroundColor='gray.100'
        display='flex'
        justifyContent='center'
        alignItems='center'
      >
        <Image src={icon} alt='icon' maxHeight='100%' height='24px' width='24px' />
      </Box>
      <Text fontSize='sm' fontWeight='semibold'>
        {name}
      </Text>
    </Box>
  );
};

export default EntityItem;
