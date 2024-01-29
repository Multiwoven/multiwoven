export type StepData = {
	step: number;
	data: any;
	stepKey: string;
};

export type ExtractedData = {
	id?: string;
	icon?: string;
	name?: string;
};

export type PrefillValue = {
	connector_id: string;
	connector_name: string;
	connector_icon: string;
	model_name: string;
	model_description: string;
};

export type DefineSQLProps = {
	hasPrefilledValues?: boolean;
	prefillValues?: PrefillValue;
	isFooterVisible?: boolean;
};
