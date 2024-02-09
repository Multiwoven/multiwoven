import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import GenerateTable from "@/components/Table/Table";
import { getUserConnectors } from "@/services/common";
import { ConvertToTableData } from "@/utils";
import { ColumnMapType } from "@/utils/types";
import { Box, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext } from "react";

const SelectModelSourceForm = (): JSX.Element | null => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const { data } = useQuery({
    queryKey: ["models", "data-source"],
    queryFn: () => getUserConnectors("source"),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
  });

  const connectors = data?.data;

  const handleOnRowClick = (row: unknown) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo?.formKey, row);
    }
  };

  if (!connectors) {
    return (
      <Box mx="auto">
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

  const columns: ColumnMapType[] = [
    { name: "Name", key: "name" },
    { name: "Type", key: "connector_name", showIcon: true },
    { name: "Created At", key: "created_at" },
  ];

  const values = ConvertToTableData(connectors?.data, columns);

  return (
    <>
      <Box w="6xl" mx="auto">
        <GenerateTable
          data={values}
          headerColorVisible={true}
          onRowClick={handleOnRowClick}
        />
      </Box>
    </>
  );
};

export default SelectModelSourceForm;
