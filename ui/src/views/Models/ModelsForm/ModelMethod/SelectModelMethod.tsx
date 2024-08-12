import { Box, Card, CardBody, HStack, Image, SimpleGrid, Stack, Text } from '@chakra-ui/react';
import { modelMethods, ModelMethodName } from './methods';
import { useContext } from 'react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { ModelMethodType } from './types';
import ContentContainer from '@/components/ContentContainer';
import Badge from '@/components/Badge';
import FormFooter from '@/components/FormFooter';
import { extractData } from '@/utils';
import { getCatalog } from '@/services/syncs';
import { useStore } from '@/stores';
import { useQuery } from '@tanstack/react-query';
import Loader from '@/components/Loader';
import { SchemaMode } from '@/views/Activate/Syncs/types';

const ModelMethod = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const extracted = extractData(state.forms);
  const connector_data = extracted.find((data) => data?.id);
  const connector_id = connector_data?.id || '';

  const { data: modelDiscoverData, isLoading } = useQuery({
    queryKey: ['syncs', 'catalog', connector_id, activeWorkspaceId],
    queryFn: () => getCatalog(connector_id),
    enabled: !!connector_id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const handleOnClick = (method: ModelMethodType) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo.formKey, method.name);
    }
  };

  if (isLoading) {
    return <Loader />;
  }

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <SimpleGrid columns={3} spacing={'24px'} maxWidth={'fit-content'}>
          {modelMethods.map((method, index) => {
            const methodProperties = { ...method };
            if (
              methodProperties.name === ModelMethodName.TableSelector &&
              modelDiscoverData?.data?.attributes?.catalog?.schema_mode === SchemaMode.schemaless
            ) {
              methodProperties.enabled = false;
            }
            return (
              <Card
                maxW='sm'
                key={index}
                _hover={methodProperties.enabled ? { bgColor: 'gray.200' } : {}}
                variant='elevated'
                onClick={
                  methodProperties.enabled ? () => handleOnClick(methodProperties) : () => {}
                }
                opacity={methodProperties.enabled ? '1' : '0.6'}
                cursor={methodProperties.enabled ? 'pointer' : 'auto'}
                borderWidth='1px'
                borderStyle='solid'
                borderColor='gray.400'
                borderRadius='8px'
                shadow={'none'}
              >
                <CardBody p={0}>
                  <Image
                    src={methodProperties.image}
                    alt={methodProperties.type}
                    borderRadius='lg'
                    w='full'
                  />
                  <Stack spacing='3' px='24px' py='20px'>
                    <HStack>
                      <Text size='lg' fontWeight='semibold'>
                        {methodProperties.name}
                      </Text>
                      {!methodProperties.enabled ? (
                        <Badge text='weaving soon' variant='default' width='fit-content' />
                      ) : (
                        <></>
                      )}
                    </HStack>
                    <Text size='sm' color='black.200' fontWeight='regular'>
                      {methodProperties.description}
                    </Text>
                  </Stack>
                </CardBody>
              </Card>
            );
          })}
        </SimpleGrid>
        <FormFooter ctaName='Continue' ctaType='submit' isBackRequired />
      </ContentContainer>
    </Box>
  );
};

export default ModelMethod;
