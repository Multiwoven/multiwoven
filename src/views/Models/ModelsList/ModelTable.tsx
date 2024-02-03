import GenerateTable from "@/components/Table/Table";
import { getAllModels } from "@/services/models";
import { AddIconDataToArray, ConvertToTableData } from "@/utils";
import { Box, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";

type ModelTableProps = {
  handleOnRowClick: (args: unknown) => void;
};

const ModelTable = ({ handleOnRowClick }: ModelTableProps): JSX.Element => {
  const { data } = useQuery({
    queryKey: ["models"],
    queryFn: () => getAllModels(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const models = data?.data?.data;

  if (!models) {
    return (
      <Box width="100%" display="flex" justifyContent="center">
        <Spinner
          thickness="4px"
          speed="0.65s"
          emptyColor="gray.200"
          color="blue.500"
          size="xl"
        />
      </Box>
    );
  }

  let values = ConvertToTableData(AddIconDataToArray(models), [
    { name: "Name", key: "name", showIcon: true },
    { name: "Query Type", key: "query_type" },
    { name: "Updated At", key: "updated_at" },
  ]);

  return (
    <GenerateTable
      data={values}
      headerColorVisible={true}
      onRowClick={handleOnRowClick}
      maxHeight="2xl"
    />
  );
};

export default ModelTable;
