import {
  chakra,
  FormControlOptions,
  HTMLChakraProps,
  Icon,
  omitThemingProps,
  Text,
  ThemingProps,
  useFormControl,
  useMergeRefs,
  useMultiStyleConfig,
  usePopper,
} from '@chakra-ui/react';
import { mergeWith } from '@chakra-ui/utils';
import { useSelect } from 'downshift';
import { Children, cloneElement, forwardRef, isValidElement, ReactElement, useMemo } from 'react';
import { SelectIcon } from './SelectIcon';
import { IconType } from 'react-icons/lib';

export interface SelectProps
  extends FormControlOptions,
    ThemingProps<'Select'>,
    Omit<
      HTMLChakraProps<'button'>,
      'disabled' | 'required' | 'readOnly' | 'size' | 'value' | 'onChange'
    > {
  placeholder?: string;
  value?: string | null | undefined;
  buttonIcon?: IconType;
  onChange?: (item: string | null | undefined) => void;
}

export const CustomSelect = forwardRef<HTMLButtonElement, SelectProps>((props, ownRef) => {
  const themed = omitThemingProps(props) as SelectProps & { 'data-testid'?: string };
  const {
    id,
    value,
    children,
    placeholder,
    buttonIcon,
    onChange,
    'data-testid': dataTestId,
    ...rest
  } = themed;
  const ownButtonProps = useFormControl<HTMLButtonElement>(rest);
  const styles = useMultiStyleConfig('CustomSelect', props);

  const validChildren = useMemo(
    () =>
      Children.toArray(children)
        .filter<ReactElement<{ value: string; children?: ReactElement }>>(isValidElement)
        .filter((child) => 'value' in child.props),
    [children],
  );

  const items = validChildren.map((child) => child.props.value);

  const { isOpen, selectedItem, getToggleButtonProps, getMenuProps, getItemProps } = useSelect({
    id,
    items,
    selectedItem: value,
    onSelectedItemChange: (val) => onChange?.(val.selectedItem),
  });

  const { referenceRef: popperRef, getPopperProps } = usePopper({
    enabled: isOpen,
    gutter: 2,
  });
  const { ref: useSelectToggleButtonRef, ...useSelectToggleButtonProps } = getToggleButtonProps();

  const toggleButtonRef = useMergeRefs(ownRef, useSelectToggleButtonRef, popperRef);
  const toggleButtonProps = mergeWith(ownButtonProps, useSelectToggleButtonProps);

  return (
    <chakra.div position='relative'>
      <chakra.button
        type='button'
        ref={toggleButtonRef}
        __css={styles.field}
        data-focus-visible-added={isOpen}
        {...toggleButtonProps}
        data-testid={dataTestId}
        display='flex'
        alignItems='center'
        width='100%'
        justifyContent='space-between'
        backgroundColor={props.isDisabled ? 'gray.300' : 'gray.100'}
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        borderRadius='6px'
        padding='6px 12px'
        cursor={props.isDisabled ? 'not-allowed' : 'pointer'}
        textColor={props.isDisabled ? 'gray.600' : 'gray.800'}
        overflow={'hidden'}
      >
        {buttonIcon && <Icon as={buttonIcon} />}
        {validChildren.find((child) => child.props.value === selectedItem)?.props.children ||
          selectedItem || (
            <Text size='sm' fontWeight={400} color='gray.600'>
              {placeholder}
            </Text>
          )}
        <SelectIcon />
      </chakra.button>
      <chakra.div
        zIndex={1000}
        width='100%'
        {...mergeWith(getPopperProps(), {
          style: { visibility: isOpen ? 'visible' : 'hidden' },
        })}
      >
        <chakra.ul
          __css={styles.menu}
          data-focus-visible-added={isOpen}
          {...getMenuProps()}
          backgroundColor='gray.100'
          borderStyle='solid'
          borderWidth='1px'
          borderColor='gray.400'
          borderRadius='6px'
          {...(props.overflowY ? { overflowY: props.overflowY } : {})}
          {...(props.maxH ? { maxH: props.maxH } : {})}
        >
          {isOpen &&
            validChildren.map((item, index) =>
              cloneElement(item, {
                __css: styles.option,
                ...getItemProps({ item: item.props.value, index }),
              }),
            )}
        </chakra.ul>
      </chakra.div>
    </chakra.div>
  );
});

CustomSelect.displayName = 'CustomSelect';
