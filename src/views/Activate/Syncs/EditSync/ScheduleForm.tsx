import {
  Box,
  Divider,
  Input,
  Radio,
  RadioGroup,
  Select,
  Stack,
  Text,
} from "@chakra-ui/react";
import { FormikProps } from "formik";
import { FinalizeSyncFormFields } from "../types";

type ScheduleFormProps = {
  formik: FormikProps<FinalizeSyncFormFields>;
};

const ScheduleForm = ({ formik }: ScheduleFormProps) => {
  return (
    <Box
      backgroundColor="gray.300"
      padding="20px"
      borderRadius="8px"
      marginBottom={"100px"}
    >
      <Text fontWeight="600" marginBottom="30px">
        Finalize settings for this sync
      </Text>
      <Box display="flex">
        <Box minWidth="500px">
          <Text marginBottom="20px" fontWeight="600">
            Schedule type
          </Text>
          <RadioGroup
            name="schedule_type"
            value={formik.values.schedule_type}
            onClick={formik.handleChange}
          >
            <Stack direction="column">
              <Radio
                value="manual"
                display="flex"
                alignItems="flex-start"
                marginBottom="10px"
                backgroundColor="#fff"
                isDisabled
              >
                <Box position="relative" top="-5px">
                  <Text fontWeight="500">Manual </Text>
                  <Text fontSize="sm">
                    Trigger your sync manually in the app or using our API{" "}
                  </Text>
                </Box>
              </Radio>
              <Radio
                value="automated"
                display="flex"
                alignItems="flex-start"
                backgroundColor="#fff"
                marginBottom="10px"
              >
                <Box position="relative" top="-5px">
                  <Text fontWeight="500">Interval </Text>
                  <Text fontSize="sm">
                    Schedule your sync to run on a set interval (e.g., once per
                    hour)
                  </Text>
                </Box>
              </Radio>
            </Stack>
          </RadioGroup>
        </Box>
        <Box minWidth="400px">
          {formik.values.schedule_type === "automated" ? (
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
                    name="sync_interval"
                    pr="4.5rem"
                    type="number"
                    placeholder="Enter a value"
                    border="none"
                    _focusVisible={{ border: "#fff" }}
                    value={formik.values.sync_interval}
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
                    name="sync_interval_unit"
                    border="none"
                    _focusVisible={{ border: "#fff" }}
                    value={formik.values.sync_interval_unit}
                    onChange={formik.handleChange}
                  >
                    <option value="minutes">Minute(s)</option>
                  </Select>
                </Box>
              </Box>
            </>
          ) : null}
        </Box>
      </Box>
    </Box>
  );
};

export default ScheduleForm;
