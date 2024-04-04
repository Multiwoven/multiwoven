import { Box, Button, Center, Flex, Heading, Image, Text, VStack } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import NoSyncsImage from '@/assets/images/NoSyncs.png';
import { useNavigate } from 'react-router-dom';

type NoActivationsProps = {
  activationType: string;
};

const NoActivations = ({ activationType }: NoActivationsProps): JSX.Element => {
  const navigate = useNavigate();

  const description =
    activationType.toLocaleLowerCase() === 'sync'
      ? 'Add a Sync to declare how you want query results from a Model to appear in your destination'
      : '';

  const image = activationType === 'sync' ? NoSyncsImage : '';

  return (
    <Flex width='100%' height='100vh' alignContent='center' justifyContent='center'>
      <Center>
        <Box maxW='sm' textAlign='center'>
          <VStack spacing={8}>
            <VStack>
              <Image src={image} />
              <Heading size='xs' color='black.500' fontWeight={600}>
                No {activationType}s found
              </Heading>
              <Text size='sm' color='black.200' fontWeight={400}>
                {description}{' '}
              </Text>
            </VStack>
            <Button onClick={() => navigate('new')} leftIcon={<FiPlus />} variant='solid' w='fit'>
              Add {activationType}
            </Button>
          </VStack>
        </Box>
      </Center>
    </Flex>
  );
};

export default NoActivations;
