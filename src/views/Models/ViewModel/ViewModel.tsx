import { useQuery } from "@tanstack/react-query";
import DefineModel from "../ModelsForm/DefineModel";
import { PrefillValue } from "../ModelsForm/DefineModel/DefineSQL/types";
import TopBar from "@/components/TopBar/TopBar";
import { getModelById } from "@/services/models";
import { useParams } from "react-router-dom";

const ViewModel = (): JSX.Element => {
	const params = useParams();

	const { data, isLoading, isError } = useQuery({
		queryKey: ["modelByID"],
		queryFn: () => getModelById(params.id || ""),
		refetchOnMount: true,
		refetchOnWindowFocus: true,
	});

	if (isLoading) {
		return <>Loading....</>;
	}

	if (isError) {
		return <>Error....</>;
	}

	if (data) {
		const prefillValues: PrefillValue = {
			connector_id: data?.data?.attributes.connector_id || 0,
			connector_icon: "",
			connector_name: "",
			model_name: data?.data?.attributes.name || "",
			model_description: data?.data?.attributes.description || "",
			primary_key: data?.data?.attributes.primary_key || "",
			query: data?.data?.attributes.query || "",
			query_type: data?.data?.attributes.query_type || "",
		};

		return (
			<>
				<TopBar name={"View Model"} />
				<DefineModel
					isFooterVisible={false}
					prefillValues={prefillValues}
					hasPrefilledValues={true}
				/>
			</>
		);
	}
	return <>Error...</>;
};

export default ViewModel;
