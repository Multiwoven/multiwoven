import { useQuery } from "@tanstack/react-query";
import { PrefillValue } from "../ModelsForm/DefineModel/DefineSQL/types";
import TopBar from "@/components/TopBar/TopBar";
import { deleteModelById, getModelById, putModelById } from "@/services/models";
import { useNavigate, useParams } from "react-router-dom";
import {
	Box,
	Button,
	Flex,
	FormControl,
	FormLabel,
	Image,
	Input,
	Select,
	Spacer,
	Text,
	Textarea,
	VStack,
	useToast,
} from "@chakra-ui/react";
import { Editor } from "@monaco-editor/react";
import { ErrorMessage, Field, Form, Formik } from "formik";
import * as Yup from "yup";
import { ModelSubmitFormValues, UpdateModelPayload } from "./types";


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
	});

	const validationSchema = Yup.object().shape({
		modelName: Yup.string().required("Model name is required"),
		description: Yup.string(),
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

	async function handleModelUpdate(values: ModelSubmitFormValues) {
		const updatePayload: UpdateModelPayload = {
			model: {
				name: values.modelName,
				description: values.description,
				primary_key: values.primaryKey,
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

	async function handleDeleteModel() {
		try {
			await deleteModelById(model_id);
			toast({
				title: "Model deleted successfully",
				status: "success",
				isClosable: true,
				duration: 5000,
				position: "bottom-right",
			})
			navigate("/define/models")
		} catch (error) {
			toast({
				title: "Unable to delete model",
				description: "error",
				status: "error",
				isClosable: true,
				duration: 5000,
				position: "bottom-right",
			});
		}
	}

	return (
		<Box width='90%' mx='auto'>
			<TopBar name={"View Model"} />
			<VStack m={8}>
				<Box p={2} w='5xl' mx='auto'>
					<Flex
						w='full'
						roundedTop='xl'
						alignItems='center'
						bgColor='gray.100'
						p={2}
					>
						<Image
							src={"/src/assets/icons/" + data.data?.attributes.connector.icon}
							p={2}
							mx={4}
							h={12}
							bgColor='gray.200'
							rounded='lg'
						/>
						<Text>{data.data?.attributes.connector.connector_name}</Text>
						<Spacer />
						<Button
							bgColor='white'
							_hover={{ bgColor: "gray.100" }}
							variant='outline'
							borderColor={"gray.500"}
							onClick={() => navigate("edit")}
						>
							Edit Query
						</Button>
					</Flex>
					<Editor
						width='100%'
						height='200px'
						language='mysql'
						defaultLanguage='mysql'
						defaultValue='Enter your query...'
						value={prefillValues.query}
						saveViewState={true}
						theme='light'
						options={{ readOnly: true }}
					/>
				</Box>
				<Box w='5xl' mx='auto' bgColor='gray.100' p={4}>
					<Text mb={6} fontWeight='bold'>
						Model Settings
					</Text>
					<Formik
						initialValues={{
							modelName: prefillValues.model_name,
							description: prefillValues.model_description,
							primaryKey: prefillValues.primary_key,
						}}
						validationSchema={validationSchema}
						onSubmit={(values) => {
							handleModelUpdate(values);
						}}
					>
						<Form>
							<VStack spacing={5}>
								<FormControl>
									<FormLabel
										htmlFor='modelName'
										fontSize='sm'
										fontWeight='semibold'
									>
										Model Name
									</FormLabel>
									<Field
										as={Input}
										id='modelName'
										name='modelName'
										placeholder='Enter a name'
										bgColor='white'
									/>
									<Text color='red.500' fontSize='sm'>
										<ErrorMessage name='modelName' />
									</Text>
								</FormControl>
								<FormControl>
									<FormLabel htmlFor='description' fontWeight='bold'>
										<Flex alignItems='center' fontSize='sm'>
											Description{" "}
											<Text ml={2} fontSize='xs'>
												{" "}
												(optional)
											</Text>
										</Flex>
									</FormLabel>
									<Field
										as={Textarea}
										id='description'
										name='description'
										placeholder='Enter a description'
										bgColor='white'
									/>
								</FormControl>
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
										bgColor='white'
										w='lg'
									/>
									<Text color='red.500' fontSize='sm'>
										<ErrorMessage name='primaryKey' />
									</Text>
								</FormControl>
								<Button type='submit'>Save Changes</Button>
							</VStack>
						</Form>
					</Formik>
				</Box>
			</VStack>
			<Button onClick={handleDeleteModel}>DELETE MODEL</Button>
		</Box>
	);
};

export default ViewModel;