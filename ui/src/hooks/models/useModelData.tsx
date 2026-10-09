import { useStore } from '@/stores';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ModelAPIResponse, getModelById } from '@/services/models';
import { PrefillValue } from '@/views/Models/ModelsForm/DefineModel/DefineSQL/types.ts';
import { GetModelByIdResponse, QueryType } from '@/views/Models/types.ts';
import EntityItem from '@/components/EntityItem';

const useModelData = (modelId: string) => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { data, isLoading, isError } = useQueryWrapper<
    ModelAPIResponse<GetModelByIdResponse>,
    Error
  >(['modelByID', activeWorkspaceId, modelId], () => getModelById(modelId || ''), {
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    retryOnMount: true,
    refetchOnReconnect: true,
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
    model_id: modelId,
  };

  return {
    prefillValues,
    data,
    isLoading,
    isError,
  };
};

export default useModelData;
