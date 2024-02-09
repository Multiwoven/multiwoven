import { useQuery } from "@tanstack/react-query";
import { PrefillValue } from "../ModelsForm/DefineModel/DefineSQL/types";
import TopBar from "@/components/TopBar/TopBar";
import { getModelById, putModelById } from "@/services/models";
import { useNavigate, useParams } from "react-router-dom";
import {
	Box,
	Button,
	Flex,
	FormControl,
	FormLabel,
	Image,
	Select,
	Spacer,
	Text,
	VStack,
	useToast,
} from "@chakra-ui/react";
import { Editor } from "@monaco-editor/react";
import { ErrorMessage, Field, Form, Formik } from "formik";
import * as Yup from "yup";
import { UpdateModelPayload } from "./types";
import DeleteModelModal from "./DeleteModelModal";
import EditModelModal from "./EditModelModal";
import ContentContainer from "@/components/ContentContainer";

const ViewModel = (): JSX.Element => {
	const params = useParams();
	const toast = useToast();
	const navigate = useNavigate();

	const model_id = params.id || "";

	const { data, isLoading, isError } = useQuery({
		queryKey: ["modelByID"],
		queryFn: () => getModelById(model_id || ""),
		refetchOnMount: true,
		refetchOnWindowFocus: true,
		retryOnMount: true,
		refetchOnReconnect: true,
	});

	const validationSchema = Yup.object().shape({
		primaryKey: Yup.string().required("Primary Key is required"),
	});

	if (isLoading) {
		return <>Loading....</>;
	}

	if (isError) {
		return <>Error....</>;
	}

	if (!data) return <></>;

	const prefillValues: PrefillValue = {
		connector_id: data?.data?.attributes.connector.id || "",
		connector_icon: data?.data?.attributes.connector.icon || "",
		connector_name: data?.data?.attributes.connector.name || "",
		model_name: data?.data?.attributes.name || "",
		model_description: data?.data?.attributes.description || "",
		primary_key: data?.data?.attributes.primary_key || "",
		query: data?.data?.attributes.query || "",
		query_type: data?.data?.attributes.query_type || "",
		model_id: model_id,
	};

	async function handleModelUpdate(primary_key: string) {
		const updatePayload: UpdateModelPayload = {
			model: {
				name: prefillValues.model_name,
				description: prefillValues.model_description,
				primary_key: primary_key || "",
				connector_id: data?.data?.attributes.connector.id || "",
				query: prefillValues.query,
				query_type: prefillValues.query_type,
			},
		};
		const modelUpdateResponse = await putModelById(model_id, updatePayload);
		if (modelUpdateResponse.data) {
			toast({
				title: "Model updated successfully",
				status: "success",
				duration: 3000,
				isClosable: true,
				position: "bottom-right",
			});
		}
	}

	return (
		<Box width='100%' display='flex' justifyContent='center'>
			<ContentContainer>
				<TopBar
					name={prefillValues.model_name}
					extra={
						<>
							<DeleteModelModal />
							<EditModelModal {...prefillValues} />
						</>
					}
				/>
				<VStack m={8}>
					<Box w='5xl'
						mx='auto'
						bgColor='gray.100'
						rounded='xl'
						>
						<Flex
							w='full'
							roundedTop='xl'
							alignItems='center'
							bgColor='gray.100'
							p={2}
							border='1px'
							borderColor='gray.400'
						>
							<Image
								src={data.data?.attributes.connector.icon || ""}
								p={2}
								mx={4}
								h={12}
								bgColor='gray.200'
								rounded='lg'
							/>
							<Text>{data.data?.attributes.connector.connector_name}</Text>
							<Spacer />
							<Button
								variant='shell'
								onClick={() => navigate("edit")}
							>
								Edit
							</Button>
						</Flex>
						<Box borderX='1px' borderBottom='1px' roundedBottom="lg" py={2} borderColor='gray.400'>
							<Editor
								width='100%'
								height='280px'
								language='mysql'
								defaultLanguage='mysql'
								defaultValue='Enter your query...'
								value={prefillValues.query}
								saveViewState={true}
								theme='light'
								options={{ readOnly: true }}
							/>
						</Box>
					</Box>
					<Box
						w='5xl'
						mx='auto'
						bgColor='gray.100'
						px={8}
						py={6}
						rounded='xl'
						border='1px'
						borderColor='gray.400'
					>
						<Text mb={6} fontWeight='bold'>
							Configure your model
						</Text>
						<Formik
							initialValues={{ primaryKey: "" }}
							validationSchema={validationSchema}
							onSubmit={(values) => handleModelUpdate(values.primaryKey)}
						>
							<Form>
								<VStack>
									<FormControl>
										<FormLabel
											htmlFor='primaryKey'
											fontSize='sm'
											fontWeight='bold'
										>
											Primary Key
										</FormLabel>
										<Field
											as={Select}
											placeholder={prefillValues.primary_key}
											name='primaryKey'
											bgColor='gray.100'
											borderColor="gray.600"
											w='lg'
											isDisabled
										/>
										<Text color='red.500' fontSize='sm'>
											<ErrorMessage name='primaryKey' />
										</Text>
									</FormControl>
								</VStack>
							</Form>
						</Formik>
					</Box>
				</VStack>
			</ContentContainer>
		</Box>
	);
};

export default ViewModel;
