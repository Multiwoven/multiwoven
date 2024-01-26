import { useContext } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import DefineSQL from "./DefineSQL";

const DefineModel = () : JSX.Element | null => {
	const { state } = useContext(SteppedFormContext);

	const dataMethod = state.forms.find((data) => data.data?.selectModelType);
	const selectedModelType = dataMethod?.data?.selectModelType;

	if (selectedModelType === "SQL Query") {
		return <DefineSQL />;
	}
	return null;
};

export default DefineModel;
