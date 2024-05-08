import { Box, Card, CardBody, HStack, Image, SimpleGrid, Stack, Text } from '@chakra-ui/react';
import { modelMethods } from './methods';
import { useContext } from 'react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { ModelMethodType } from './types';
import ContentContainer from '@/components/ContentContainer';
import Badge from '@/components/Badge';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';

const ModelMethod = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const handleOnClick = (method: ModelMethodType) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo.formKey, method.name);
    }
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <SimpleGrid columns={3} spacing={'24px'} maxWidth={'fit-content'}>
          {modelMethods.map((method, index) => (
            <Card
              maxW='sm'
              key={index}
              _hover={method.enabled ? { bgColor: 'gray.200' } : {}}
              variant='elevated'
              onClick={method.enabled ? () => handleOnClick(method) : () => {}}
              opacity={method.enabled ? '1' : '0.6'}
              cursor={method.enabled ? 'pointer' : 'auto'}
              borderWidth='1px'
              borderStyle='solid'
              borderColor='gray.400'
              borderRadius='8px'
              shadow={'none'}
            >
              <CardBody p={0}>
                <Image src={method.image} alt={method.type} borderRadius='lg' w='full' />
                <Stack spacing='3' px='24px' py='20px'>
                  <HStack>
                    <Text size='lg' fontWeight='semibold'>
                      {method.name}
                    </Text>
                    {!method.enabled ? (
                      <Badge text='weaving soon' variant='default' width='fit-content' />
                    ) : (
                      <></>
                    )}
                  </HStack>
                  <Text size='sm' color='black.200' fontWeight='regular'>
                    {method.description}
                  </Text>
                </Stack>
              </CardBody>
            </Card>
          ))}
        </SimpleGrid>
        <SourceFormFooter ctaName='Continue' ctaType='submit' isBackRequired />
      </ContentContainer>
    </Box>
  );
};

export default ModelMethod;
