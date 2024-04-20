import { Button, Center, Flex, Heading, Image, VStack, Text } from '@chakra-ui/react';
import MLOpsLanding from '@/assets/images/ml-ops-landing.svg';

const MLOps = () => (
  <Flex width='100%' height='100vh' alignContent='center' justifyContent='center'>
    <Center>
      <VStack>
        <Text color='brand.400' size='sm' fontWeight='bold' letterSpacing='2.24px'>
          AI Squared ML OPS
        </Text>
        <Heading size='md' fontWeight='bold' letterSpacing='-0.36px'>
          Activate AI models
        </Heading>
        <Heading size='md' fontWeight='bold' letterSpacing='-0.36px'>
          for business application
        </Heading>
        <Text color='black.200' size='md' fontWeight={400}>
          Seamlessly integrate AI into your existing business workflows
        </Text>
        <Button
          onClick={() =>
            window.open('https://squared.ai/contact/', '_blank', 'noopener noreferrer')
          }
          variant='solid'
          w='fit'
          marginTop='32px'
          _focusVisible={{ bgColor: 'brand.400' }}
        >
          Contact Us
        </Button>
        <VStack marginTop='44px'>
          <Image src={MLOpsLanding} />
        </VStack>
      </VStack>
    </Center>
  </Flex>
);

export default MLOps;
