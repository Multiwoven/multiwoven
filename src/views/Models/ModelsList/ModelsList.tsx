import GenerateTable from "@/components/Table/Table";
import TopBar from "@/components/TopBar";
import { getAllModels } from "@/services/models";
import { ConvertToTableData } from "@/utils";
import { Box } from "@chakra-ui/react";
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

	const models = data?.data;

	const navigate = useNavigate();

	if (!models) return null;

	let values = ConvertToTableData(models.data, [
		"name",
		"query_type",
		"updated_at",
	], ["Name", "Method", "Last Updated"]);
	
  console.log("Values", values);

	return (
		<Box width='90%' mx='auto' py={12}>
			<TopBar
				name={"Models"}
				ctaName='Add model'
				ctaIcon={<FiPlus color='gray.100' />}
				ctaBgColor={"orange.500"}
				ctaHoverBgColor={"orange.400"}
				ctaColor={"white"}
				onCtaClicked={() => navigate("new")}
				isCtaVisible
			/>
			<GenerateTable data={values} />
			<Outlet />
		</Box>
	);
};

export default ModelsList;
