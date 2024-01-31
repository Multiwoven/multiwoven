import { useContext } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import DefineSQL from "./DefineSQL";
import { DefineSQLProps } from "./DefineSQL/types";

const DefineModel = (props: DefineSQLProps): JSX.Element | null => {
	const { state } = useContext(SteppedFormContext);

	const dataMethod = state.forms.find((data) => data.data?.selectModelType);
	const selectedModelType = dataMethod?.data?.selectModelType;

	if (selectedModelType === "SQL Query") {
		return <DefineSQL {...props} />;
	}
	return null;
};

export default DefineModel;
