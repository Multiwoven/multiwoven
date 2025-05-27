import GenerateTable from '@/components/Table/Table';
import { AllDataModels, getAllModels, GetAllModelsResponse } from '@/services/models';
import { addIconDataToArray, ConvertToTableData } from '@/utils';
import NoModels from '@/views/Models/NoModels';
import Loader from '@/components/Loader';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { useStore } from '@/stores';
import { ApiResponse } from '@/services/common';

type ModelTableProps = {
  handleOnRowClick: (args: unknown) => void;
  models?: GetAllModelsResponse[];
};

const ModelTable = ({ handleOnRowClick, models }: ModelTableProps): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  // If models are not provided as props, fetch them
  const { data } = useQueryWrapper<ApiResponse<GetAllModelsResponse[]>, Error>(
    ['models', activeWorkspaceId],
    () => getAllModels({ type: AllDataModels }),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
      enabled: !models, // Only fetch if models are not provided
    },
  );

  const modelData = models || data?.data;

  if (!modelData) {
    return <Loader />;
  }

  if (modelData.length === 0) return <NoModels />;


  const values = ConvertToTableData(addIconDataToArray(modelData), [
    { name: 'Name', key: 'name', showIcon: true },
    { name: 'Query Type', key: 'query_type' },
    { name: 'Updated At', key: 'updated_at' },
  ]);

  return (
    <GenerateTable
      data={values}
      headerColorVisible={true}
      onRowClick={handleOnRowClick}
      maxHeight='2xl'
    />
  );
};

export default ModelTable;
