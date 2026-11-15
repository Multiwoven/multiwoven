import { useQuery } from '@tanstack/react-query';
import DefineSQL from '../ModelsForm/DefineModel/DefineSQL';
import { useParams } from 'react-router-dom';
import { Box } from '@chakra-ui/react';
<<<<<<< HEAD
import { getModelById } from '@/services/models';
import { PrefillValue } from '../ModelsForm/DefineModel/DefineSQL/types';
=======
>>>>>>> 8f1c21c9 (refactor(CE): models creation flow)
import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import Loader from '@/components/Loader';
import { Step } from '@/components/Breadcrumbs/types';
import { useRef } from 'react';
import { QueryType } from '../types';
import TableSelector from '../ModelsForm/DefineModel/TableSelector';
import useModelData from '@/hooks/models/useModelData.tsx';

const EditModel = (): JSX.Element => {
  const params = useParams();
  const containerRef = useRef(null);

  const model_id = params.id || '';

<<<<<<< HEAD
  const { data, isLoading, isError } = useQuery({
    queryKey: ['modelByID'],
    queryFn: () => getModelById(model_id || ''),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
  });

  const prefillValues: PrefillValue = {
    connector_id: data?.data?.attributes.connector.id || '',
    connector_icon: (
      <EntityItem
        name={data?.data?.attributes.connector.name || ''}
        icon={data?.data?.attributes.connector.icon || ''}
      />
    ),
    connector_name: data?.data?.attributes.connector.name || '',
    model_name: data?.data?.attributes.name || '',
    model_description: data?.data?.attributes.description || '',
    primary_key: data?.data?.attributes.primary_key || '',
    query: data?.data?.attributes.query || '',
    query_type: data?.data?.attributes.query_type || QueryType.RawSql,
    model_id: model_id,
  };
=======
  const { prefillValues, data, isLoading, isError } = useModelData(model_id);
>>>>>>> 8f1c21c9 (refactor(CE): models creation flow)

  if (isLoading) {
    return <Loader />;
  }

  if (isError) {
    return <>Error....</>;
  }

  const EDIT_QUERY_FORM_STEPS: Step[] = [
    {
      name: 'Models',
      url: '/define/models',
    },
    {
      name: data?.data?.attributes?.name || '',
      url: `/define/models/${model_id}`,
    },
    {
      name: 'Edit Query',
      url: '',
    },
  ];

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer containerRef={containerRef}>
        <TopBar name='' breadcrumbSteps={EDIT_QUERY_FORM_STEPS} />
        {prefillValues.query_type === QueryType.TableSelector ? (
          <TableSelector
            hasPrefilledValues={true}
            prefillValues={prefillValues}
            isUpdateButtonVisible={true}
          />
        ) : (
          <DefineSQL
            isFooterVisible={false}
            hasPrefilledValues={true}
            prefillValues={prefillValues}
            isUpdateButtonVisible={true}
            isAlignToContentContainer={true}
          />
        )}
      </ContentContainer>
    </Box>
  );
};

export default EditModel;
