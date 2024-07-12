import { Box, Image, Text, VStack } from '@chakra-ui/react';
import EmptyQueryPreviewImage from '@/assets/images/EmptyQueryPreview.svg';

const ModelQueryResults = () => {
  return (
    <Box
      border='1px'
      borderColor='gray.400'
      w='full'
      minW='4xl'
      minH='100%'
      h='2xs'
      rounded='xl'
      p={1}
      alignItems='center'
      justifyContent='center'
    >
      <VStack mx='auto' mt={12}>
        <Image src={EmptyQueryPreviewImage} h='20' />
        <Text size='md' fontWeight='semibold'>
          Test your query
        </Text>
        <Text size='sm' color='black.200' fontWeight='regular'>
          Run your query to preview the rows
        </Text>
      </VStack>
    </Box>
  );
};

export default ModelQueryResults;
