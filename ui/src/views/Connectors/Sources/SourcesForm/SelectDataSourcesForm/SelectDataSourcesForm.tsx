import { useContext } from 'react';
import { Box, Image, Text } from '@chakra-ui/react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorsDefintions } from '@/services/connectors';
import { useQuery } from '@tanstack/react-query';
import { DatasourceType } from '@/views/Connectors/types';
import ContentContainer from '@/components/ContentContainer';

const SelectDataSourcesForm = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const { data } = useQuery({
    queryKey: ['datasources', 'source'],
    queryFn: () => getConnectorsDefintions('source'),
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    gcTime: Infinity,
  });

  const datasources = data?.data ?? [];

  const handleOnClick = (datasource: DatasourceType) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo.formKey, datasource.name);
    }
  };

  return (
    <Box display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <Box
          display={{ base: 'block', md: 'grid' }}
          gridTemplateColumns='1fr 1fr'
          gap='24px'
          marginBottom='20px'
          paddingY='10px'
          width='100%'
        >
          {datasources.map((datasource) => (
            <Box
              key={datasource.name}
              display='flex'
              alignItems='center'
              borderWidth='thin'
              padding='20px'
              borderRadius='8px'
              cursor='pointer'
              borderColor='gray.400'
              _hover={{
                backgroundColor: 'gray.200',
              }}
              height='56px'
              onClick={() => handleOnClick(datasource)}
            >
              <Box
                height='40px'
                width='40px'
                marginRight='10px'
                borderWidth='thin'
                padding='5px'
                borderRadius='8px'
                display='flex'
                justifyContent='center'
                alignItems='center'
                backgroundColor='gray.100'
              >
                <Image
                  src={datasource.icon}
                  alt='source icon'
                  maxHeight='100%'
                  height='24px'
                  width='24px'
                />
              </Box>
              <Text fontWeight='semibold' size='sm'>
                {datasource.title}
              </Text>
            </Box>
          ))}
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SelectDataSourcesForm;
