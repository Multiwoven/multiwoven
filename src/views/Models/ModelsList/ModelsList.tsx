import ContentContainer from "@/components/ContentContainer";
import GenerateTable from "@/components/Table/Table";
import TopBar from "@/components/TopBar";
import { getAllModels } from "@/services/models";
import { addIconDataToArray, ConvertToTableData } from "@/utils";
import { Box, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FiPlus } from "react-icons/fi";
import { Outlet, useNavigate } from "react-router-dom";
import NoModels from "../NoModels";

const ModelsList = (): JSX.Element | null => {
	const { data } = useQuery({
		queryKey: ["models"],
		queryFn: () => getAllModels(),
		refetchOnMount: true,
		refetchOnWindowFocus: false,
	});

	let models = data?.data?.data;

	const navigate = useNavigate();

	if (!models) {
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

	models = addIconDataToArray(models);

	let values = ConvertToTableData(models, [
		{ name: "Name", key: "name", showIcon: true },
		{ name: "Query Type", key: "query_type" },
		{ name: "Updated At", key: "updated_at" },
	]);

	const handleOnRowClick = (row: any) => {
		navigate(row?.id);
	};

	return (
		<Box width='100%' display='flex' flexDirection='column' alignItems='center'>
			<ContentContainer>
				{models.length === 0 ? (
					<NoModels />
				) : (
					<>
						<TopBar
							name={"Models"}
							ctaName='Add model'
							ctaIcon={<FiPlus color='gray.100' />}
							ctaBgColor={"brand.500"}
							ctaHoverBgColor={"brand.400"}
							ctaColor={"white"}
							onCtaClicked={() => navigate("new")}
							isCtaVisible
						/>
						<Box mt={16}>
							<GenerateTable
								data={values}
								headerColorVisible={true}
								onRowClick={handleOnRowClick}
								maxHeight='2xl'
							/>
						</Box>
					</>
				)}

				<Outlet />
			</ContentContainer>
		</Box>
	);
};

export default ModelsList;
