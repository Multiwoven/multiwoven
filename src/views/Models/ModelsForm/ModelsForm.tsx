import SteppedForm from "@/components/SteppedForm";

import {
	Box,
	Drawer,
	DrawerBody,
	DrawerContent,
	DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";
import SelectModelSourceForm from "./SelectModelSourceForm";
import ModelMethod from "./ModelMethod";


const ModelsForm = (): JSX.Element => {
	const navigate = useNavigate();
	const steps = [
		{
			formKey: "datasource",
			name: "Select a data source",
			component: <SelectModelSourceForm />,
			isRequireContinueCta: true,
			beforeNextStep: () => true,
		},
		{
			formKey: "selectModelType",
			name: "Select a Modelling Method",
			component: <ModelMethod />,
			isRequireContinueCta: false,
			beforeNextStep: () => true,
		},
		{
			formKey: "defineModel",
			name: "Define your model",
			component: <>dffd</>,
			isRequireContinueCta: true,
			beforeNextStep: () => false,
		},
	];

	return (
		<Drawer isOpen onClose={() => navigate(-1)} placement='right' size='100%'>
			<DrawerOverlay />
			<DrawerContent>
				<DrawerBody>
					<Box width='100%'>
						<SteppedForm steps={steps} />
					</Box>
				</DrawerBody>
			</DrawerContent>
		</Drawer>
	);
};

export default ModelsForm;
