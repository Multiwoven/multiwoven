import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import GenerateTable from "@/components/Table/Table";
import { getUserConnectors } from "@/services/common";
import { ConvertToTableData } from "@/utils";
import { Box, Container, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext } from "react";
import { useNavigate } from "react-router-dom";

const SelectModelSourceForm = (): JSX.Element | null => {
	// const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);

	const { data } = useQuery({
		queryKey: ["connectors", "source"],
		queryFn: () => getUserConnectors("Source"),
		refetchOnMount: false,
		refetchOnWindowFocus: false,
	});

	const connectors = data?.data;

	if (!connectors) {
		return (
			<Box mx='auto'>
				<Spinner
					thickness='4px'
					speed='0.65s'
					emptyColor='gray.200'
					color='blue.500'
					size='xl'
				/>
			</Box>
		);
	}

	let values = ConvertToTableData(
		connectors?.data,
		["name", "connector_name", "updated_at"],
		["Name", "Type", "Last Updated"]
	);

	return (
		<>
			<Box w='6xl' mx='auto'>
				<GenerateTable data={values} />
			</Box>
		</>
	);
};

export default SelectModelSourceForm;
