import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";
import {
  Box,
  Divider,
  Input,
  Radio,
  RadioGroup,
  Select,
  Stack,
  Text,
  Textarea,
} from "@chakra-ui/react";
import { useFormik } from "formik";
import { useContext } from "react";

const FinaliseSync = (): JSX.Element => {
  const { state } = useContext(SteppedFormContext);

  const { forms } = state;
  const syncConfigForm = forms.find(
    (form) => form.stepKey === "configureSyncs"
  );
  const syncConfigData = syncConfigForm?.data;

  const formik = useFormik({
    initialValues: {
      description: "",
      intervalType: "manual",
      interval: 0,
      intervalUnit: "min",
    },
    onSubmit: (data) => {},
  });

  return (
    <Box display="flex" width="100%" justifyContent="center">
      <ContentContainer>
        <form onSubmit={formik.handleSubmit}>
          <Box
            backgroundColor="gray.200"
            padding="20px"
            borderRadius="8px"
            marginBottom="100px"
          >
            <Text fontWeight="600" marginBottom="20px">
              Finalise setting for this sync
            </Text>
            <Text marginBottom="10px">Description (Optional)</Text>
            <Textarea
              name="description"
              value={formik.values.description}
              placeholder="Enter a description"
              background="#fff"
              resize="none"
              marginBottom="30px"
              onChange={formik.handleChange}
            />

            <Box display="flex">
              <Box minWidth="500px">
                <Text marginBottom="20px" fontWeight="600">
                  Schedule type
                </Text>
                <RadioGroup
                  name="intervalType"
                  value={formik.values.intervalType}
                  onClick={formik.handleChange}
                >
                  <Stack direction="column">
                    <Radio
                      value="manual"
                      display="flex"
                      alignItems="flex-start"
                      marginBottom="10px"
                      backgroundColor="#fff"
                    >
                      <Box position="relative" top="-5px">
                        <Text fontWeight="500">Manual </Text>
                        <Text fontSize="sm">
                          Trigger your sync manually in the app or using our API{" "}
                        </Text>
                      </Box>
                    </Radio>
                    <Radio
                      value="interval"
                      display="flex"
                      alignItems="flex-start"
                      backgroundColor="#fff"
                      marginBottom="10px"
                    >
                      <Box position="relative" top="-5px">
                        <Text fontWeight="500">Interval </Text>
                        <Text fontSize="sm">
                          Schedule your sync to run on a set interval (e.g.,
                          once per hour)
                        </Text>
                      </Box>
                    </Radio>
                  </Stack>
                </RadioGroup>
              </Box>
              <Box minWidth="400px">
                {formik.values.intervalType === "interval" ? (
                  <>
                    <Text marginBottom="20px" fontWeight="600">
                      Schedule Configuration
                    </Text>
                    <Box
                      border="thin"
                      padding="5px 10px 5px 20px"
                      display="flex"
                      backgroundColor="#fff"
                      borderRadius="8px"
                      alignItems="center"
                    >
                      <Box>
                        <Text>Every</Text>
                      </Box>
                      <Box>
                        <Input
                          name="interval"
                          pr="4.5rem"
                          type="number"
                          placeholder="Enter a value"
                          border="none"
                          _focusVisible={{ border: "#fff" }}
                          value={formik.values.interval}
                          onChange={formik.handleChange}
                          isRequired
                        />
                      </Box>
                      <Divider
                        orientation="vertical"
                        height="24px"
                        color="gray.400"
                      />
                      <Box>
                        <Select
                          name="intervalUnit"
                          border="none"
                          _focusVisible={{ border: "#fff" }}
                          value={formik.values.intervalUnit}
                          onChange={formik.handleChange}
                        >
                          <option>Minute(s)</option>
                          <option>Hour(s)</option>
                          <option>Day(s)</option>
                          <option>Week(s)</option>
                        </Select>
                      </Box>
                    </Box>
                  </>
                ) : null}
              </Box>
            </Box>
          </Box>
          <SourceFormFooter ctaName="Finish" ctaType="submit" />
        </form>
      </ContentContainer>
    </Box>
  );
};

export default FinaliseSync;
