import GenerateTable from "@/components/Table/Table";
import TopBar from "@/components/TopBar";
import { getAllModels } from "@/services/models";
import { AddIconDataToArray, ConvertToTableData } from "@/utils";
import { Box, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FiPlus } from "react-icons/fi";
import { Outlet, useNavigate } from "react-router-dom";

const ModelsList = (): JSX.Element | null => {
  const { data } = useQuery({
    queryKey: ["models"],
    queryFn: () => getAllModels(),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  let models = data?.data?.data;

  const navigate = useNavigate();

  if (!models) {
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

  models = AddIconDataToArray(models);

  let values = ConvertToTableData(models, [
    { name: "Name", key: "name" },
    { name: "Query Type", key: "query_type" },
    { name: "Updated At", key: "updated_at" },
  ]);  
  
  const handleOnRowClick = (row: any) => {
    navigate(row?.id);
  };

  return (
    <Box width="90%" mx="auto" py={12}>
      <TopBar
        name={"Models"}
        ctaName="Add model"
        ctaIcon={<FiPlus color="gray.100" />}
        ctaBgColor={"orange.500"}
        ctaHoverBgColor={"orange.400"}
        ctaColor={"white"}
        onCtaClicked={() => navigate("new")}
        isCtaVisible
      />
      <Box mt={16}>
        <GenerateTable
          data={values}
          headerColorVisible={true}
          onRowClick={handleOnRowClick}
        />
      </Box>
      <Outlet />
    </Box>
  );
};

export default ModelsList;
