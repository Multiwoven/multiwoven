import { Box, Radio, RadioGroup, Stack, Text } from '@chakra-ui/react';
import { FormikProps } from 'formik';

type ScheduleTypeSelectorProps = {
  formik: FormikProps<any>;
};

const RenderRadio = ({
  value,
  label,
  description,
}: {
  value: string;
  label: string;
  description: string;
}) => (
  <Radio
    value={value}
    display='flex'
    alignItems='flex-start'
    backgroundColor='gray.100'
    marginBottom='10px'
    borderColor='gray.400'
    borderWidth='1.5px'
    borderStyle='solid'
  >
    <Box position='relative' top='-5px'>
      <Text fontWeight='medium' size='sm'>
        {label}
      </Text>
      <Text size='xs' color='black.200'>
        {description}
      </Text>
    </Box>
  </Radio>
);

const ScheduleTypeSelector = ({ formik }: ScheduleTypeSelectorProps) => (
  <Box>
    <Text mb='4' fontWeight='semibold' size='sm'>
      Schedule type
    </Text>
    <RadioGroup
      name='schedule_type'
      value={formik.values.schedule_type}
      onClick={formik.handleChange}
    >
      <Stack direction='column'>
        <RenderRadio
          value='manual'
          label='Manual'
          description='Trigger your sync manually in the app'
        />
        <RenderRadio
          value='interval'
          label='Interval'
          description='Schedule your sync to run on a set interval (e.g., once per hour)'
        />
        <RenderRadio
          value='cron_expression'
          label='Cron Expression'
          description='Schedule your sync using a cron expression'
        />
      </Stack>
    </RadioGroup>
  </Box>
);

export default ScheduleTypeSelector;
