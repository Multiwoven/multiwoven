import ModelTable from "@/components/ModelTable";
import GenerateTable from "@/components/Table/Table";
import { ModelTableDataType } from "@/components/Table/types";
import TopBar from "@/components/TopBar";
import { getAllModels } from "@/services/models";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FiPlus } from "react-icons/fi";
import { Outlet, useNavigate } from "react-router-dom";

const ModelsList = (): JSX.Element | null => {
  // const { data } = useQuery({
  //   queryKey: ["models"],
  //   queryFn: () => getAllModels(),
  //   refetchOnMount: false,
  //   refetchOnWindowFocus: false,
  // });

  // const models = data?.data;

  const navigate = useNavigate();

  // if (!models) return null;

  const sampleData:ModelTableDataType = {
    columns:['Name','Method','Last Updated'],
    data: [{
      name: "Model 1",
      method: "SQL Query",
      last_updated:"12/12/23"
    }]
  }

  return (
    <Box width="90%" mx="auto">
      <TopBar
        name={"Models"}
        ctaName="Add model"
        ctaIcon={<FiPlus color="gray.100" />}
        onCtaClicked={() => navigate("new")}
        isCtaVisible
      />
      {/* <ModelTable models={models} /> */}
      <GenerateTable title="dkjfhu" data={sampleData} />
      <Outlet />
    </Box>
  );
};

export default ModelsList;
