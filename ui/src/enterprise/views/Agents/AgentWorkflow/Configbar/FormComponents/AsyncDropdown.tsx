import ToolTip from '@/components/ToolTip';
import { getUserConnectors } from '@/services/connectors';
import { Text, Flex, Box, Image } from '@chakra-ui/react';
import { WidgetProps } from '@rjsf/utils';
import { FiCheck, FiInfo } from 'react-icons/fi';
import { components, MenuListProps, OptionProps, GroupBase, Select } from 'chakra-react-select';
import { useQuery } from '@tanstack/react-query';
import { getEmbeddingConfiguration } from '@/enterprise/services/embeddingConfiguration';
import useAgentStore from '@/enterprise/store/useAgentStore';
import { WorkflowPayload } from '@/enterprise/services/types';
import { FlowComponent } from '../../../types';
import { BaseWidgetOption } from './types';
import { getKnowledgeBases } from '@/enterprise/services/knowledge-base';

type DropdownOptions = BaseWidgetOption & {
  data?: keyof typeof SERVICES;
  label_key?: string;
  value_key?: string;
  enumOptions?: { label: string; value: string }[];
  filters: {
    type: string;
    category: string;
    page: number;
    per_page: string;
    sub_category: string;
  };
};

type AsyncDropdownOptions = {
  label: string;
  value: string;
  icon?: string;
};

const SERVICES: Record<
  string,
  (
    filters: DropdownOptions['filters'],
    currentWorkflow: WorkflowPayload | null,
    selectedComponent: FlowComponent | null,
  ) => Promise<any>
> = {
  data_source: (filters) =>
    getUserConnectors(
      filters.type,
      filters.category,
      filters.page,
      filters.per_page,
      filters.sub_category,
    ),
  embeddings: () => getEmbeddingConfiguration(),
  knowledgeBases: () => getKnowledgeBases(),
  componentInputs: (_, currentWorkflow, selectedComponent) =>
    Promise.resolve({
      data:
        currentWorkflow && selectedComponent
          ? currentWorkflow.workflow.edges.filter(
              (edge) => edge.target_component_id === selectedComponent.id,
            )
          : [],
    }),
};

const buildDropdownOptions = (data: any[], labelKey?: string, valueKey?: string) => {
  if (!Array.isArray(data) || !labelKey || !valueKey) {
    return [];
  }
  if (labelKey && valueKey) {
    return data.map((opt) => {
      const label =
        labelKey.split('.').reduce((acc, key) => acc?.[key], opt.attributes) ??
        labelKey.split('.').reduce((acc, key) => acc?.[key], opt) ??
        '';
      const value =
        valueKey.split('.').reduce((acc, key) => acc?.[key], opt) ??
        valueKey.split('.').reduce((acc, key) => acc?.[key], opt.attributes) ??
        '';
      return {
        label: label,
        value: value,
        icon: opt?.attributes?.icon,
      };
    });
  }
  return [];
};

// Custom Option Component
const CustomOption = <
  IsMulti extends boolean = false,
  Group extends GroupBase<AsyncDropdownOptions> = GroupBase<AsyncDropdownOptions>,
>(
  props: OptionProps<AsyncDropdownOptions, IsMulti, Group>,
) => {
  const { data, isFocused, isSelected } = props;

  return (
    <components.Option {...props}>
      <Flex
        alignItems='center'
        justifyContent='space-between'
        px='12px'
        py='8px'
        bg='gray.100'
        borderRadius='4px'
        color='black.500'
        bgColor={isSelected || isFocused ? 'gray.300' : 'gray.100'}
      >
        <Flex gap='8px' alignItems='center'>
          {data.icon && (
            <Flex
              justifyContent='center'
              alignItems='center'
              border='1px solid'
              borderColor='gray.400'
              borderRadius='3px'
              height='20px'
              width='20px'
              bgColor='gray.100'
              padding='2px'
            >
              <Image src={data.icon} />
            </Flex>
          )}
          {data.label}
        </Flex>
        {isSelected && (
          <Box color='brand.400'>
            <FiCheck />
          </Box>
        )}
      </Flex>
    </components.Option>
  );
};

const CustomMenuList = <
  OptionType,
  IsMulti extends boolean = false,
  Group extends GroupBase<OptionType> = GroupBase<OptionType>,
>(
  props: MenuListProps<OptionType, IsMulti, Group>,
) => {
  const hasOptions = props.children && Array.isArray(props.children) && props.children.length > 0;

  return (
    <components.MenuList {...props}>
      <Box
        border='1px solid'
        borderColor='gray.400'
        borderRadius='6px'
        bgColor='gray.100'
        zIndex={99999}
      >
        <Box padding='4px'>
          {hasOptions ? (
            props.children
          ) : (
            <Box px={3} py={2}>
              <Text fontSize='sm' color='gray.400'>
                No results found
              </Text>
            </Box>
          )}
        </Box>
      </Box>
    </components.MenuList>
  );
};

const AsyncDropdown = ({
  id,
  value,
  required,
  disabled,
  onChange,
  label,
  options,
  formContext,
}: WidgetProps) => {
  const { data, watch, label_key, value_key, enumOptions, filters, tooltip, input_placeholder } =
    options as DropdownOptions;
  const currentWorkflow = useAgentStore((state) => state.currentWorkflow);
  const selectedComponent = useAgentStore((state) => state.selectedComponent);
  const watchedValue = watch ? formContext.configuration?.[watch] : undefined;
  const service = SERVICES[data ?? 'data_source'];
  const { data: dropdownData, isLoading } = useQuery({
    queryKey: ['dropdown-widget', options?.data, filters ? { ...filters } : undefined],
    queryFn: () => {
      if (!service) {
        console.warn(`No service defined for dropdown data source: ${data}`);
        return null;
      }
      return service(filters, currentWorkflow, selectedComponent);
    },
    enabled: options?.data !== undefined && (!watch || watchedValue !== undefined),
  });

  const dropdownOptions =
    enumOptions && !options?.data
      ? enumOptions
      : buildDropdownOptions(dropdownData?.data ?? [], label_key, value_key);

  const defaultValue = dropdownOptions?.find((opt) => opt.value === value);

  return (
    <Flex
      gap='10px'
      flexDir='column'
      data-testid={id ? `workflow-config-dropdown-${id}` : undefined}
    >
      <Flex gap='8px' alignItems={'center'}>
        <Flex gap='4px'>
          <Text size={'sm'} fontWeight={600}>
            {label}
          </Text>
          {required && <Box color='error.400'>*</Box>}
        </Flex>
        {tooltip && (
          <ToolTip label={tooltip as string}>
            <Box color='gray.600'>
              <FiInfo width='14px' height='14px' />
            </Box>
          </ToolTip>
        )}
      </Flex>
      <Box
        data-testid={id ? `workflow-config-async-combobox-${id}` : 'workflow-config-async-combobox'}
      >
        <Select<AsyncDropdownOptions>
          id={id}
          key={`async-dropdown-${filters?.type}-${filters?.category}-${filters?.page}-${filters?.per_page}-${filters?.sub_category}`}
          defaultValue={dropdownOptions?.[0]?.value}
          isLoading={isLoading}
          value={defaultValue}
          isRequired={required}
          isDisabled={disabled}
          options={dropdownOptions}
          placeholder={input_placeholder as string}
          onChange={(option) => onChange(option?.value)}
          components={{
            Option: CustomOption,
            MenuList: CustomMenuList,
          }}
          styles={{
            option: (base) => ({
              ...base,
              padding: 0,
              borderRadius: '6px',
              backgroundColor: 'transparent',
            }),
            menuList: (base) => ({
              ...base,
              zIndex: 999999999999,
              maxHeight: '50vh',
              overflowY: 'auto',
            }),
          }}
        />
      </Box>
    </Flex>
  );
};

export default AsyncDropdown;
