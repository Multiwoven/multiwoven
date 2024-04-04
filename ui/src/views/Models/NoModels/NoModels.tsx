import { Button, Center, Flex, Heading, Image, Text, VStack } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import NoModelsImage from '@/assets/images/NoModels.png';
import { useNavigate } from 'react-router-dom';

const NoModels = (): JSX.Element => {
  const navigate = useNavigate();
  return (
    <Flex width='100%' height='100%' alignContent='center' justifyContent='center'>
      <Center>
        <VStack spacing={8}>
          <VStack>
            <Image src={NoModelsImage} />
            <Heading size='xs' color='black.500' letterSpacing='-0.24px' fontWeight={600}>
              No Models added
            </Heading>
            <Text size='sm' color='black.200' letterSpacing='-0.14px' fontWeight={400}>
              Add a Model to describe how your data source will be queried{' '}
            </Text>
          </VStack>
          <Button
            onClick={() => navigate('/define/models/new', { replace: true })}
            leftIcon={<FiPlus />}
            letterSpacing='-0.14px'
          >
            Add Model
          </Button>
        </VStack>
      </Center>
    </Flex>
  );
};

export default NoModels;
