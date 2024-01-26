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
		queryKey: ["connectors", "source"],
		queryFn: () => getUserConnectors("Source"),
		refetchOnMount: false,
		refetchOnWindowFocus: false,
	});

	const connectors = data?.data;

	const handleOnRowClick = (row: any) => {
		if (stepInfo?.formKey) {
			handleMoveForward(stepInfo?.formKey, row);
		}
	};

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

	const columns: ColumnMapType[] = [
		{ name: "Name", key: "name" },
		{ name: "Connector Type", key: "connector_type" },
	];

	let values = ConvertToTableData(connectors?.data, columns);

	return (
		<>
			<Box w='6xl' mx='auto'>
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
