import { Stack, RadioGroup, Radio, Box, Divider, Text, Input } from '@chakra-ui/react';
import { useState, SetStateAction, Dispatch } from 'react';

type StaticOptionsProps = {
  staticValues: string[];
  selectedStaticOptionValue: string | boolean;
  setSelectedStaticOptionValue: Dispatch<SetStateAction<string | boolean>>;
};

enum STATIC_OPTION_TYPE {
  STRING = 'string',
  BOOLEAN = 'boolean',
  NULL = 'null',
  NUMBER = 'number',
}

const StaticOptions = ({
  staticValues,
  selectedStaticOptionValue,
  setSelectedStaticOptionValue,
}: StaticOptionsProps): JSX.Element => {
  const [selectedStaticValue, setSelectedStaticValue] = useState<STATIC_OPTION_TYPE | string>(
    STATIC_OPTION_TYPE.STRING,
  );

  return (
    <Stack gap='20px' height='100%' direction='row'>
      <RadioGroup
        onChange={(value) => {
          setSelectedStaticValue(value);
          setSelectedStaticOptionValue('');
        }}
        value={selectedStaticValue}
      >
        <Stack direction='column'>
          {staticValues.map((staticValue, index) => (
            <Radio
              size='lg'
              value={staticValue}
              key={index}
              padding='8px 12px'
              colorScheme='red'
              borderColor='gray.400'
              borderWidth='1.5px'
            >
              <Text size='md' fontWeight={500}>
                {staticValue}
              </Text>
            </Radio>
          ))}
        </Stack>
      </RadioGroup>
      <Box>
        <Divider orientation='vertical' borderColor='gray.300' opacity={1} />
      </Box>
      <Box width='100%'>
        {(selectedStaticValue as STATIC_OPTION_TYPE) === STATIC_OPTION_TYPE.BOOLEAN && (
          <RadioGroup
            onChange={(value) => setSelectedStaticOptionValue(value === 'true')}
            value={selectedStaticOptionValue.toString()}
            colorScheme='red'
          >
            <Stack direction='row'>
              <Radio
                size='lg'
                padding='8px 12px'
                value='true'
                borderColor='gray.400'
                borderWidth='1.5px'
              >
                <Text size='md' fontWeight={500}>
                  True
                </Text>
              </Radio>
              <Radio
                size='lg'
                padding='8px 12px'
                value='false'
                borderColor='gray.400'
                borderWidth='1.5px'
              >
                <Text size='md' fontWeight={500}>
                  False
                </Text>
              </Radio>
            </Stack>
          </RadioGroup>
        )}
        {(selectedStaticValue as STATIC_OPTION_TYPE) === STATIC_OPTION_TYPE.NUMBER && (
          <Box padding='8px 12px'>
            <Input
              name='static_number'
              pr='4.5rem'
              type='number'
              placeholder='Enter number'
              _focusVisible={{
                borderStyle: '1px',
                borderWidth: 'solid',
                borderColor: 'black.100',
              }}
              _hover={{ borderStyle: '1px', borderWidth: 'solid', borderColor: 'black.100' }}
              value={selectedStaticOptionValue.toString()}
              onChange={({ target: { value } }) => setSelectedStaticOptionValue(value)}
              isRequired
              color='gray.600'
              height='35px'
              borderStyle='1px'
              borderWidth='solid'
              borderColor='black.100'
            />
          </Box>
        )}
        {(selectedStaticValue as STATIC_OPTION_TYPE) === STATIC_OPTION_TYPE.STRING && (
          <Box padding='8px 12px'>
            <Input
              name='static_string'
              pr='4.5rem'
              type='text'
              placeholder='Enter string'
              _focusVisible={{
                borderStyle: '1px',
                borderWidth: 'solid',
                borderColor: 'black.100',
              }}
              _hover={{ borderStyle: '1px', borderWidth: 'solid', borderColor: 'black.100' }}
              value={selectedStaticOptionValue.toString()}
              onChange={({ target: { value } }) => setSelectedStaticOptionValue(value)}
              isRequired
              color='gray.600'
              height='35px'
              borderStyle='1px'
              borderWidth='solid'
              borderColor='black.100'
            />
            <Text color='black.200' size='xs' fontWeight={500} paddingTop={1}>
              Strings can include any combination of numbers, letters, and special characters.
            </Text>
          </Box>
        )}
        {(selectedStaticValue as STATIC_OPTION_TYPE) === STATIC_OPTION_TYPE.NULL && (
          <Box padding='8px 12px'>
            <Text color='black.200' size='xs' fontWeight={500}>
              A null value be synced to this destination field.
            </Text>
          </Box>
        )}
      </Box>
    </Stack>
  );
};

export default StaticOptions;
